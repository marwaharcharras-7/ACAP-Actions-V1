import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

interface UserToCreate {
  email: string;
  password: string;
  firstName: string;
  lastName: string;
  role: 'admin' | 'manager' | 'supervisor' | 'team_leader' | 'operator';
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

    // Create admin client with service role key
    const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false,
      },
    });

    // Parse request body for users to create
    const body = await req.json();
    const usersToCreate: UserToCreate[] = body.users || [];

    const results = [];

    for (const user of usersToCreate) {
      console.log(`Creating user: ${user.email}`);

      // Check if user already exists
      const { data: existingUsers } = await supabaseAdmin.auth.admin.listUsers();
      const existingUser = existingUsers?.users?.find(u => u.email === user.email);

      if (existingUser) {
        console.log(`User ${user.email} already exists, updating role...`);
        
        // Update the role in user_roles table
        const { error: roleError } = await supabaseAdmin
          .from('user_roles')
          .upsert({
            user_id: existingUser.id,
            role: user.role,
          }, { onConflict: 'user_id' });

        if (roleError) {
          console.error(`Error updating role for ${user.email}:`, roleError);
        }

        results.push({
          email: user.email,
          status: 'already_exists',
          userId: existingUser.id,
          roleUpdated: !roleError,
        });
        continue;
      }

      // Create user with admin API
      const { data: newUser, error: createError } = await supabaseAdmin.auth.admin.createUser({
        email: user.email,
        password: user.password,
        email_confirm: true, // Auto-confirm email
        user_metadata: {
          first_name: user.firstName,
          last_name: user.lastName,
        },
      });

      if (createError) {
        console.error(`Error creating user ${user.email}:`, createError);
        results.push({
          email: user.email,
          status: 'error',
          error: createError.message,
        });
        continue;
      }

      console.log(`User ${user.email} created successfully with ID: ${newUser.user.id}`);

      // The trigger handle_new_user() will create the profile with 'operator' role
      // Now we need to update the role if it's different
      if (user.role !== 'operator') {
        console.log(`Updating role for ${user.email} to ${user.role}`);
        
        // Wait a bit for the trigger to execute
        await new Promise(resolve => setTimeout(resolve, 500));

        const { error: roleError } = await supabaseAdmin
          .from('user_roles')
          .update({ role: user.role })
          .eq('user_id', newUser.user.id);

        if (roleError) {
          console.error(`Error updating role for ${user.email}:`, roleError);
        } else {
          console.log(`Role updated successfully for ${user.email}`);
        }
      }

      results.push({
        email: user.email,
        status: 'created',
        userId: newUser.user.id,
        role: user.role,
      });
    }

    console.log('All users processed:', JSON.stringify(results, null, 2));

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Users processed successfully',
        results,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      }
    );
  } catch (error: unknown) {
    const errorMessage = error instanceof Error ? error.message : 'Unknown error';
    console.error('Error in create-users function:', error);
    return new Response(
      JSON.stringify({
        success: false,
        error: errorMessage,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500,
      }
    );
  }
});

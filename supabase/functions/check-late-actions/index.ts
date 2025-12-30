import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: corsHeaders })
  }

  try {
    console.log('Starting check-late-actions job...')

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Get current timestamp
    const now = new Date().toISOString()
    console.log(`Checking for late actions at: ${now}`)

    // Find all actions that are in_progress or planned with due_date in the past
    const { data: lateActions, error: fetchError } = await supabase
      .from('actions')
      .select('id, title, status, due_date')
      .in('status', ['in_progress', 'planned', 'identified'])
      .lt('due_date', now)

    if (fetchError) {
      console.error('Error fetching actions:', fetchError)
      throw fetchError
    }

    console.log(`Found ${lateActions?.length || 0} actions with passed due date`)

    if (!lateActions || lateActions.length === 0) {
      return new Response(
        JSON.stringify({ 
          success: true, 
          message: 'No late actions found',
          updated: 0 
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Update each action to 'late' status
    const actionIds = lateActions.map(a => a.id)
    
    const { data: updatedActions, error: updateError } = await supabase
      .from('actions')
      .update({ status: 'late' })
      .in('id', actionIds)
      .select('id, title')

    if (updateError) {
      console.error('Error updating actions:', updateError)
      throw updateError
    }

    console.log(`Updated ${updatedActions?.length || 0} actions to 'late' status:`)
    updatedActions?.forEach(a => console.log(`  - ${a.title} (${a.id})`))

    return new Response(
      JSON.stringify({ 
        success: true, 
        message: `Updated ${updatedActions?.length || 0} actions to late status`,
        updated: updatedActions?.length || 0,
        actions: updatedActions
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error: unknown) {
    const errorMessage = error instanceof Error ? error.message : 'Unknown error'
    console.error('Error in check-late-actions:', errorMessage)
    return new Response(
      JSON.stringify({ success: false, error: errorMessage }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})

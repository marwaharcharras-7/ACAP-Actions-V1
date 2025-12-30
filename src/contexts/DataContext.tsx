import React, { createContext, useContext, ReactNode } from 'react';
import { Action, Service, Line, Team, Post, User, DashboardStats, UserRole, Factory } from '@/types';
import { 
  useActions, 
  useServices, 
  useLines, 
  useTeams, 
  usePosts, 
  useUsers,
  useFactories,
  useAddAction,
  useUpdateAction,
  useDeleteAction,
  useAddUser,
  useUpdateUser,
  useDeleteUser,
  useAddService,
  useUpdateService,
  useDeleteService,
  useAddLine,
  useUpdateLine,
  useDeleteLine,
  useAddTeam,
  useUpdateTeam,
  useDeleteTeam,
  useAddPost,
  useUpdatePost,
  useDeletePost,
} from '@/hooks/useSupabaseData';

interface DataContextType {
  actions: Action[];
  factories: Factory[];
  services: Service[];
  lines: Line[];
  teams: Team[];
  posts: Post[];
  users: User[];
  stats: DashboardStats;
  isLoading: boolean;
  addAction: (action: Omit<Action, 'id' | 'createdAt' | 'updatedAt' | 'pilotName' | 'createdByName' | 'serviceName' | 'lineName' | 'teamName' | 'postName' | 'attachments'>) => Promise<void>;
  updateAction: (id: string, updates: Partial<Action>) => Promise<void>;
  deleteAction: (id: string) => void;
  addUser: (user: { firstName: string; lastName: string; role: UserRole; lineId?: string; teamId?: string; postId?: string; isActive?: boolean }) => Promise<{ email: string; password: string }>;
  updateUser: (id: string, updates: Partial<User>) => void;
  deleteUser: (id: string) => void;
  addService: (service: Omit<Service, 'id'>) => Promise<void>;
  updateService: (id: string, updates: Partial<Service>) => void;
  deleteService: (id: string) => void;
  addLine: (line: Omit<Line, 'id' | 'serviceName' | 'teamLeaderName'>) => Promise<void>;
  updateLine: (id: string, updates: Partial<Line>) => void;
  deleteLine: (id: string) => void;
  addTeam: (team: Omit<Team, 'id' | 'lineName' | 'leaderName'>) => Promise<void>;
  updateTeam: (id: string, updates: Partial<Team>) => void;
  deleteTeam: (id: string) => void;
  addPost: (post: Omit<Post, 'id' | 'teamName' | 'lineId' | 'lineName'>) => Promise<void>;
  updatePost: (id: string, updates: Partial<Post>) => void;
  deletePost: (id: string) => void;
  refreshData: () => void;
}

const DataContext = createContext<DataContextType | undefined>(undefined);

const getDashboardStats = (actions: Action[]): DashboardStats => {
  const stats: DashboardStats = {
    totalActions: actions.length,
    identified: actions.filter(a => a.status === 'identified').length,
    planned: actions.filter(a => a.status === 'planned').length,
    inProgress: actions.filter(a => a.status === 'in_progress').length,
    completed: actions.filter(a => a.status === 'completed').length,
    late: actions.filter(a => a.status === 'late').length,
    validated: actions.filter(a => a.status === 'validated').length,
    archived: actions.filter(a => a.status === 'archived').length,
    onTimeRate: 0,
    avgEfficiency: 0,
  };

  const completedActions = actions.filter(a => a.status === 'completed' || a.status === 'validated');
  if (completedActions.length > 0) {
    const onTime = completedActions.filter(a => {
      if (!a.completedAt) return false;
      return new Date(a.completedAt) <= new Date(a.dueDate);
    });
    stats.onTimeRate = Math.round((onTime.length / completedActions.length) * 100);
    
    const withEfficiency = completedActions.filter(a => a.efficiencyPercent !== undefined);
    if (withEfficiency.length > 0) {
      stats.avgEfficiency = Math.round(
        withEfficiency.reduce((sum, a) => sum + (a.efficiencyPercent || 0), 0) / withEfficiency.length
      );
    }
  }

  return stats;
};

export const DataProvider = ({ children }: { children: ReactNode }) => {
  const { data: actions = [], isLoading: actionsLoading, refetch: refetchActions } = useActions();
  const { data: factories = [], isLoading: factoriesLoading, refetch: refetchFactories } = useFactories();
  const { data: services = [], isLoading: servicesLoading, refetch: refetchServices } = useServices();
  const { data: lines = [], isLoading: linesLoading, refetch: refetchLines } = useLines();
  const { data: teams = [], isLoading: teamsLoading, refetch: refetchTeams } = useTeams();
  const { data: posts = [], isLoading: postsLoading, refetch: refetchPosts } = usePosts();
  const { data: users = [], isLoading: usersLoading, refetch: refetchUsers } = useUsers();

  // Action mutations
  const addActionMutation = useAddAction();
  const updateActionMutation = useUpdateAction();
  const deleteActionMutation = useDeleteAction();
  
  // User mutations
  const addUserMutation = useAddUser();
  const updateUserMutation = useUpdateUser();
  const deleteUserMutation = useDeleteUser();
  
  // Service mutations
  const addServiceMutation = useAddService();
  const updateServiceMutation = useUpdateService();
  const deleteServiceMutation = useDeleteService();
  
  // Line mutations
  const addLineMutation = useAddLine();
  const updateLineMutation = useUpdateLine();
  const deleteLineMutation = useDeleteLine();
  
  // Team mutations
  const addTeamMutation = useAddTeam();
  const updateTeamMutation = useUpdateTeam();
  const deleteTeamMutation = useDeleteTeam();
  
  // Post mutations
  const addPostMutation = useAddPost();
  const updatePostMutation = useUpdatePost();
  const deletePostMutation = useDeletePost();

  const isLoading = actionsLoading || factoriesLoading || servicesLoading || linesLoading || teamsLoading || postsLoading || usersLoading;
  const stats = getDashboardStats(actions);

  const addAction = async (action: Omit<Action, 'id' | 'createdAt' | 'updatedAt' | 'pilotName' | 'createdByName' | 'serviceName' | 'lineName' | 'teamName' | 'postName' | 'attachments'>) => {
    await addActionMutation.mutateAsync(action);
  };

  const updateAction = async (id: string, updates: Partial<Action>): Promise<void> => {
    await updateActionMutation.mutateAsync({ id, updates });
  };

  const deleteAction = (id: string) => {
    deleteActionMutation.mutate(id);
  };

  const addUser = async (user: { firstName: string; lastName: string; role: UserRole; lineId?: string; teamId?: string; postId?: string; isActive?: boolean }): Promise<{ email: string; password: string }> => {
    return await addUserMutation.mutateAsync(user);
  };

  const updateUser = (id: string, updates: Partial<User>) => {
    updateUserMutation.mutate({ id, updates });
  };

  const deleteUser = (id: string) => {
    deleteUserMutation.mutate(id);
  };

  const addService = async (service: Omit<Service, 'id'>) => {
    await addServiceMutation.mutateAsync(service);
  };

  const updateService = (id: string, updates: Partial<Service>) => {
    updateServiceMutation.mutate({ id, updates });
  };

  const deleteService = (id: string) => {
    deleteServiceMutation.mutate(id);
  };

  const addLine = async (line: Omit<Line, 'id' | 'serviceName' | 'teamLeaderName'>) => {
    await addLineMutation.mutateAsync(line);
  };

  const updateLine = (id: string, updates: Partial<Line>) => {
    updateLineMutation.mutate({ id, updates });
  };

  const deleteLine = (id: string) => {
    deleteLineMutation.mutate(id);
  };

  const addTeam = async (team: Omit<Team, 'id' | 'lineName' | 'leaderName'>) => {
    await addTeamMutation.mutateAsync(team);
  };

  const updateTeam = (id: string, updates: Partial<Team>) => {
    updateTeamMutation.mutate({ id, updates });
  };

  const deleteTeam = (id: string) => {
    deleteTeamMutation.mutate(id);
  };

  const addPost = async (post: Omit<Post, 'id' | 'teamName' | 'lineId' | 'lineName'>) => {
    await addPostMutation.mutateAsync(post);
  };

  const updatePost = (id: string, updates: Partial<Post>) => {
    updatePostMutation.mutate({ id, updates });
  };

  const deletePost = (id: string) => {
    deletePostMutation.mutate(id);
  };

  const refreshData = () => {
    refetchActions();
    refetchFactories();
    refetchServices();
    refetchLines();
    refetchTeams();
    refetchPosts();
    refetchUsers();
  };

  return (
    <DataContext.Provider
      value={{
        actions,
        factories,
        services,
        lines,
        teams,
        posts,
        users,
        stats,
        isLoading,
        addAction,
        updateAction,
        deleteAction,
        addUser,
        updateUser,
        deleteUser,
        addService,
        updateService,
        deleteService,
        addLine,
        updateLine,
        deleteLine,
        addTeam,
        updateTeam,
        deleteTeam,
        addPost,
        updatePost,
        deletePost,
        refreshData,
      }}
    >
      {children}
    </DataContext.Provider>
  );
};

export const useData = () => {
  const context = useContext(DataContext);
  if (context === undefined) {
    throw new Error('useData must be used within a DataProvider');
  }
  return context;
};

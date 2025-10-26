import { authAPI } from '../services/api';
import config from '../config';

export const checkAuth = () => {
  return authAPI.isAuthenticated();
};

export const getUser = () => {
  return authAPI.getCurrentUser();
};

export const hasRole = (role) => {
  const user = getUser();
  return user && user.role === role;
};

export const isAdmin = () => {
  return hasRole(config.roles.ADMIN);
};

export const isTecnico = () => {
  return hasRole(config.roles.TECNICO);
};

export const isCliente = () => {
  return hasRole(config.roles.CLIENTE);
};

export const canEditTicket = (ticket) => {
  const user = getUser();
  if (!user) return false;
  
  // Admin y técnicos pueden editar todos
  if (user.role === config.roles.ADMIN || user.role === config.roles.TECNICO) {
    return true;
  }
  
  // Clientes solo sus propios tickets
  if (user.role === config.roles.CLIENTE) {
    return ticket.user_id === user.id;
  }
  
  return false;
};

export const canDeleteTicket = (ticket) => {
  const user = getUser();
  if (!user) return false;
  
  // Solo admin y técnicos pueden eliminar
  return user.role === config.roles.ADMIN || user.role === config.roles.TECNICO;
};

export const canAssignTicket = () => {
  const user = getUser();
  if (!user) return false;
  
  // Solo admin y técnicos pueden asignar
  return user.role === config.roles.ADMIN || user.role === config.roles.TECNICO;
};
const config = {
  apiUrl: process.env.REACT_APP_API_URL || 'http://localhost:8001',
  uploadMaxSize: parseInt(process.env.REACT_APP_UPLOAD_MAX_SIZE) || 5242880,
  allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'pdf'],
  
  // Endpoints
  endpoints: {
    auth: {
      login: '/auth/login',
      register: '/auth/register',
      me: '/auth/me'
    },
    users: '/api/users',
    tickets: '/api/tickets',
    upload: '/api/upload',
    stats: '/api/stats',
    health: '/api/health'
  },
  
  // Roles
  roles: {
    ADMIN: 'admin',
    TECNICO: 'tecnico',
    CLIENTE: 'cliente'
  },
  
  // Estados de tickets
  ticketStatus: {
    ABIERTO: 'abierto',
    EN_PROCESO: 'en_proceso',
    RESUELTO: 'resuelto',
    CERRADO: 'cerrado'
  },
  
  // Prioridades
  ticketPriority: {
    BAJA: 'baja',
    MEDIA: 'media',
    ALTA: 'alta',
    URGENTE: 'urgente'
  }
};

export default config;
import axios from 'axios';
import config from '../config';

// Crear instancia de axios
const api = axios.create({
  baseURL: config.apiUrl,
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json',
  }
});

// Interceptor para agregar token a las peticiones
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    console.log(`🔵 ${config.method.toUpperCase()} ${config.url}`);
    return config;
  },
  (error) => {
    console.error('❌ Request Error:', error);
    return Promise.reject(error);
  }
);

// Interceptor para manejar respuestas y errores
api.interceptors.response.use(
  (response) => {
    console.log(`✅ ${response.config.method.toUpperCase()} ${response.config.url} - ${response.status}`);
    return response;
  },
  (error) => {
    console.error('❌ Response Error:', error.response?.data || error.message);
    
    // Si es error 401, redirigir a login
    if (error.response?.status === 401) {
      localStorage.removeItem('token');
      localStorage.removeItem('user');
      window.location.href = '/login';
    }
    
    return Promise.reject(error);
  }
);

// ==================== AUTENTICACIÓN ====================

export const authAPI = {
  login: async (email, password) => {
    const formData = new FormData();
    formData.append('username', email); // FastAPI OAuth2 usa 'username'
    formData.append('password', password);
    
    const response = await api.post(config.endpoints.auth.login, formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      }
    });
    
    // Guardar token y usuario
    if (response.data.access_token) {
      localStorage.setItem('token', response.data.access_token);
      localStorage.setItem('user', JSON.stringify(response.data.user));
    }
    
    return response.data;
  },
  
  register: async (userData) => {
    const response = await api.post(config.endpoints.auth.register, userData);
    return response.data;
  },
  
  getMe: async () => {
    const response = await api.get(config.endpoints.auth.me);
    return response.data;
  },
  
  logout: () => {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    window.location.href = '/login';
  },
  
  getCurrentUser: () => {
    const userStr = localStorage.getItem('user');
    return userStr ? JSON.parse(userStr) : null;
  },
  
  isAuthenticated: () => {
    return !!localStorage.getItem('token');
  }
};

// ==================== USUARIOS ====================

export const usersAPI = {
  getAll: () => api.get(config.endpoints.users),
  getById: (id) => api.get(`${config.endpoints.users}/${id}`),
  create: (userData) => api.post(config.endpoints.users, userData),
  update: (id, userData) => api.put(`${config.endpoints.users}/${id}`, userData),
  delete: (id) => api.delete(`${config.endpoints.users}/${id}`)
};

// ==================== TICKETS ====================

export const ticketsAPI = {
  getAll: async () => {
    const response = await api.get(config.endpoints.tickets);
    return response.data;
  },
  
  getById: async (id) => {
    const response = await api.get(`${config.endpoints.tickets}/${id}`);
    return response.data;
  },
  
  create: async (ticketData) => {
    const response = await api.post(config.endpoints.tickets, ticketData);
    return response.data;
  },
  
  update: async (id, ticketData) => {
    const response = await api.put(`${config.endpoints.tickets}/${id}`, ticketData);
    return response.data;
  },
  
  delete: async (id) => {
    const response = await api.delete(`${config.endpoints.tickets}/${id}`);
    return response.data;
  },
  
  // Filtros específicos
  getByStatus: async (status) => {
    const tickets = await ticketsAPI.getAll();
    return tickets.filter(ticket => ticket.status === status);
  },
  
  getByPriority: async (priority) => {
    const tickets = await ticketsAPI.getAll();
    return tickets.filter(ticket => ticket.priority === priority);
  }
};

// ==================== UPLOADS ====================

export const uploadAPI = {
  uploadFile: async (file) => {
    const formData = new FormData();
    formData.append('file', file);
    
    const response = await api.post(config.endpoints.upload, formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      }
    });
    
    return response.data;
  },
  
  validateFile: (file) => {
    const ext = file.name.split('.').pop().toLowerCase();
    
    if (!config.allowedExtensions.includes(ext)) {
      throw new Error(`Tipo de archivo no permitido. Permitidos: ${config.allowedExtensions.join(', ')}`);
    }
    
    if (file.size > config.uploadMaxSize) {
      throw new Error(`Archivo demasiado grande. Máximo: ${config.uploadMaxSize / 1024 / 1024}MB`);
    }
    
    return true;
  }
};

// ==================== ESTADÍSTICAS ====================

export const statsAPI = {
  getStats: async () => {
    const response = await api.get(config.endpoints.stats);
    return response.data;
  }
};

// ==================== HEALTH CHECK ====================

export const healthAPI = {
  check: async () => {
    const response = await api.get(config.endpoints.health);
    return response.data;
  },
  
  testDatabase: async () => {
    const response = await api.get('/api/test-db');
    return response.data;
  }
};

export default api;
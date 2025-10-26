import React from 'react';
import { Navigate } from 'react-router-dom';
import { checkAuth, hasRole } from '../utils/auth';

const PrivateRoute = ({ children, requiredRole }) => {
  const isAuthenticated = checkAuth();
  
  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }
  
  if (requiredRole && !hasRole(requiredRole)) {
    return <Navigate to="/unauthorized" replace />;
  }
  
  return children;
};

export default PrivateRoute;
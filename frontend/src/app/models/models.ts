export interface User {
  id: number;
  username: string;
  email: string;
  full_name?: string;
  is_active: boolean;
  is_admin: boolean;
}

export interface Category {
  id: number;
  name: string;
  icon: string;
  description?: string;
}

export interface Course {
  id: number;
  title: string;
  description?: string;
  category_id?: number;
  total_lessons: number;
  total_duration: number;
  created_at: string;
}

export interface LoginRequest {
  username: string;
  password: string;
}

export interface LoginResponse {
  access_token: string;
  token_type: string;
}

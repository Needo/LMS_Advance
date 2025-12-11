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

export interface LessonNode {
  id: number;
  title: string;
  file_type: string;
  file_path: string;
  order: number;
  duration?: number;
}

export interface ModuleNode {
  id: number;
  title: string;
  order: number;
  file_path?: string;
  lessons: LessonNode[];
  children: ModuleNode[];
}

export interface CourseTree extends Course {
  file_path: string;
  modules: ModuleNode[];
}

export interface LoginRequest {
  username: string;
  password: string;
}

export interface LoginResponse {
  access_token: string;
  token_type: string;
}

export interface ScanResult {
  success: boolean;
  message: string;
  courses_created: number;
  courses_updated: number;
  modules_created: number;
  lessons_created: number;
  categories_created: number;
}

# ============================================================
# LMS Angular UI - Complete Generator
# Save as: C:\Projects\LMS-System\frontend\generate_ui.ps1
# Run from: C:\Projects\LMS-System\frontend\
# ============================================================

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  LMS Angular UI Generator" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Stop ng serve if running
Write-Host "Make sure 'ng serve' is stopped (Ctrl+C)" -ForegroundColor Yellow
Write-Host "Press Enter to continue..." -ForegroundColor Yellow
$null = Read-Host

# Create folder structure
Write-Host "`nCreating folder structure..." -ForegroundColor Green
New-Item -ItemType Directory -Force -Path "src\app\models" | Out-Null
New-Item -ItemType Directory -Force -Path "src\app\services" | Out-Null
New-Item -ItemType Directory -Force -Path "src\app\components\login" | Out-Null
New-Item -ItemType Directory -Force -Path "src\app\components\header" | Out-Null
New-Item -ItemType Directory -Force -Path "src\app\components\sidebar" | Out-Null
New-Item -ItemType Directory -Force -Path "src\app\components\course-browser" | Out-Null
New-Item -ItemType Directory -Force -Path "src\app\components\course-viewer" | Out-Null
New-Item -ItemType Directory -Force -Path "src\app\guards" | Out-Null

Write-Host "[OK] Folders created" -ForegroundColor Gray

# ============================================================
# Models
# ============================================================
$modelTs = @'
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
'@
$modelTs | Out-File -FilePath "src\app\models\models.ts" -Encoding UTF8
Write-Host "[OK] src\app\models\models.ts" -ForegroundColor Gray

# ============================================================
# Auth Service
# ============================================================
$authServiceTs = @'
import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { BehaviorSubject, Observable, tap } from 'rxjs';
import { LoginRequest, LoginResponse, User } from '../models/models';

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  private apiUrl = 'http://localhost:8000/api';
  private currentUserSubject = new BehaviorSubject<User | null>(null);
  public currentUser$ = this.currentUserSubject.asObservable();

  constructor(private http: HttpClient) {
    this.loadUserFromStorage();
  }

  login(credentials: LoginRequest): Observable<LoginResponse> {
    return this.http.post<LoginResponse>(`${this.apiUrl}/auth/login`, credentials)
      .pipe(
        tap(response => {
          localStorage.setItem('access_token', response.access_token);
          this.loadCurrentUser();
        })
      );
  }

  logout(): void {
    localStorage.removeItem('access_token');
    this.currentUserSubject.next(null);
  }

  getToken(): string | null {
    return localStorage.getItem('access_token');
  }

  isAuthenticated(): boolean {
    return !!this.getToken();
  }

  private loadCurrentUser(): void {
    if (this.isAuthenticated()) {
      this.http.get<User>(`${this.apiUrl}/auth/me`).subscribe({
        next: (user) => this.currentUserSubject.next(user),
        error: () => this.logout()
      });
    }
  }

  private loadUserFromStorage(): void {
    if (this.isAuthenticated()) {
      this.loadCurrentUser();
    }
  }
}
'@
$authServiceTs | Out-File -FilePath "src\app\services\auth.service.ts" -Encoding UTF8
Write-Host "[OK] src\app\services\auth.service.ts" -ForegroundColor Gray

# ============================================================
# Course Service
# ============================================================
$courseServiceTs = @'
import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { Course, Category } from '../models/models';

@Injectable({
  providedIn: 'root'
})
export class CourseService {
  private apiUrl = 'http://localhost:8000/api';

  constructor(private http: HttpClient) {}

  getCategories(): Observable<Category[]> {
    return this.http.get<Category[]>(`${this.apiUrl}/categories`);
  }

  getAllCourses(): Observable<Course[]> {
    return this.http.get<Course[]>(`${this.apiUrl}/courses`);
  }

  getCoursesByCategory(categoryId: number): Observable<Course[]> {
    return this.http.get<Course[]>(`${this.apiUrl}/courses/category/${categoryId}`);
  }

  getCourse(courseId: number): Observable<Course> {
    return this.http.get<Course>(`${this.apiUrl}/courses/${courseId}`);
  }
}
'@
$courseServiceTs | Out-File -FilePath "src\app\services\course.service.ts" -Encoding UTF8
Write-Host "[OK] src\app\services\course.service.ts" -ForegroundColor Gray

# ============================================================
# Auth Guard
# ============================================================
$authGuardTs = @'
import { inject } from '@angular/core';
import { Router } from '@angular/router';
import { AuthService } from '../services/auth.service';

export const authGuard = () => {
  const authService = inject(AuthService);
  const router = inject(Router);

  if (authService.isAuthenticated()) {
    return true;
  }

  router.navigate(['/login']);
  return false;
};
'@
$authGuardTs | Out-File -FilePath "src\app\guards\auth.guard.ts" -Encoding UTF8
Write-Host "[OK] src\app\guards\auth.guard.ts" -ForegroundColor Gray

# ============================================================
# HTTP Interceptor
# ============================================================
$interceptorTs = @'
import { HttpInterceptorFn } from '@angular/common/http';

export const authInterceptor: HttpInterceptorFn = (req, next) => {
  const token = localStorage.getItem('access_token');
  
  if (token) {
    const cloned = req.clone({
      headers: req.headers.set('Authorization', `Bearer ${token}`)
    });
    return next(cloned);
  }
  
  return next(req);
};
'@
$interceptorTs | Out-File -FilePath "src\app\auth.interceptor.ts" -Encoding UTF8
Write-Host "[OK] src\app\auth.interceptor.ts" -ForegroundColor Gray

# ============================================================
# Login Component
# ============================================================
$loginComponentTs = @'
import { Component } from '@angular/core';
import { Router } from '@angular/router';
import { FormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { AuthService } from '../../services/auth.service';
import { LoginRequest } from '../../models/models';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [CommonModule, FormsModule],
  templateUrl: './login.component.html',
  styleUrls: ['./login.component.scss']
})
export class LoginComponent {
  credentials: LoginRequest = { username: '', password: '' };
  error = '';
  loading = false;

  constructor(
    private authService: AuthService,
    private router: Router
  ) {}

  login(): void {
    this.loading = true;
    this.error = '';
    
    this.authService.login(this.credentials).subscribe({
      next: () => {
        this.router.navigate(['/courses']);
      },
      error: (err) => {
        this.error = 'Invalid username or password';
        this.loading = false;
      }
    });
  }
}
'@
$loginComponentTs | Out-File -FilePath "src\app\components\login\login.component.ts" -Encoding UTF8

$loginComponentHtml = @'
<div class="login-container">
  <div class="login-box">
    <h1>📚 LMS System</h1>
    <h2>Login</h2>
    
    <form (ngSubmit)="login()" #loginForm="ngForm">
      <div class="form-group">
        <label>Username</label>
        <input 
          type="text" 
          [(ngModel)]="credentials.username" 
          name="username"
          required
          placeholder="Enter username"
        >
      </div>
      
      <div class="form-group">
        <label>Password</label>
        <input 
          type="password" 
          [(ngModel)]="credentials.password" 
          name="password"
          required
          placeholder="Enter password"
        >
      </div>
      
      <div class="error" *ngIf="error">{{ error }}</div>
      
      <button type="submit" [disabled]="loading || !loginForm.form.valid">
        {{ loading ? 'Logging in...' : 'Login' }}
      </button>
      
      <div class="hint">
        <small>Default: username: <strong>admin</strong>, password: <strong>admin123</strong></small>
      </div>
    </form>
  </div>
</div>
'@
$loginComponentHtml | Out-File -FilePath "src\app\components\login\login.component.html" -Encoding UTF8

$loginComponentScss = @'
.login-container {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.login-box {
  background: white;
  padding: 40px;
  border-radius: 10px;
  box-shadow: 0 10px 25px rgba(0,0,0,0.2);
  width: 100%;
  max-width: 400px;

  h1 {
    text-align: center;
    margin-bottom: 10px;
    font-size: 2.5em;
  }

  h2 {
    text-align: center;
    margin-bottom: 30px;
    color: #333;
  }
}

.form-group {
  margin-bottom: 20px;

  label {
    display: block;
    margin-bottom: 5px;
    color: #555;
    font-weight: 500;
  }

  input {
    width: 100%;
    padding: 12px;
    border: 2px solid #e1e1e1;
    border-radius: 5px;
    font-size: 14px;
    box-sizing: border-box;

    &:focus {
      outline: none;
      border-color: #667eea;
    }
  }
}

button {
  width: 100%;
  padding: 12px;
  background: #667eea;
  color: white;
  border: none;
  border-radius: 5px;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  transition: background 0.3s;

  &:hover:not(:disabled) {
    background: #5568d3;
  }

  &:disabled {
    background: #ccc;
    cursor: not-allowed;
  }
}

.error {
  color: #d32f2f;
  margin-bottom: 15px;
  padding: 10px;
  background: #ffebee;
  border-radius: 5px;
  font-size: 14px;
}

.hint {
  margin-top: 15px;
  text-align: center;
  color: #666;
}
'@
$loginComponentScss | Out-File -FilePath "src\app\components\login\login.component.scss" -Encoding UTF8
Write-Host "[OK] Login component created" -ForegroundColor Gray

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "  Part 1 Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "`nGenerating remaining components..." -ForegroundColor Yellow
Write-Host "Press Enter to continue..." -ForegroundColor Yellow
$null = Read-Host
# ============================================================
# LMS Angular - Complete Update Script
# Save as: C:\Projects\LMS-System\frontend\update_all_files.ps1
# Run from: C:\Projects\LMS-System\frontend\
# ============================================================

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  LMS Angular - Complete Setup" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Create models folder
New-Item -ItemType Directory -Force -Path "src\app\models" | Out-Null

# ============================================================
# 1. MODELS
# ============================================================
Write-Host "Creating models..." -ForegroundColor Yellow
$modelsTs = @'
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
$modelsTs | Out-File -FilePath "src\app\models\models.ts" -Encoding UTF8
Write-Host "[OK] models.ts" -ForegroundColor Green

# ============================================================
# 2. AUTH SERVICE
# ============================================================
Write-Host "Updating auth service..." -ForegroundColor Yellow
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
Write-Host "[OK] auth.service.ts" -ForegroundColor Green

# ============================================================
# 3. COURSE SERVICE
# ============================================================
Write-Host "Updating course service..." -ForegroundColor Yellow
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
Write-Host "[OK] course.service.ts" -ForegroundColor Green

# ============================================================
# 4. AUTH GUARD
# ============================================================
Write-Host "Updating auth guard..." -ForegroundColor Yellow
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
Write-Host "[OK] auth.guard.ts" -ForegroundColor Green

# ============================================================
# 5. AUTH INTERCEPTOR
# ============================================================
Write-Host "Updating auth interceptor..." -ForegroundColor Yellow
$authInterceptorTs = @'
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
$authInterceptorTs | Out-File -FilePath "src\app\auth.interceptor.ts" -Encoding UTF8
Write-Host "[OK] auth.interceptor.ts" -ForegroundColor Green

# ============================================================
# 6. APP CONFIG
# ============================================================
Write-Host "Updating app config..." -ForegroundColor Yellow
$appConfigTs = @'
import { ApplicationConfig, provideZoneChangeDetection } from '@angular/core';
import { provideRouter } from '@angular/router';
import { provideHttpClient, withInterceptors } from '@angular/common/http';
import { routes } from './app.routes';
import { authInterceptor } from './auth.interceptor';

export const appConfig: ApplicationConfig = {
  providers: [
    provideZoneChangeDetection({ eventCoalescing: true }),
    provideRouter(routes),
    provideHttpClient(withInterceptors([authInterceptor]))
  ]
};
'@
$appConfigTs | Out-File -FilePath "src\app\app.config.ts" -Encoding UTF8
Write-Host "[OK] app.config.ts" -ForegroundColor Green

# ============================================================
# 7. APP ROUTES
# ============================================================
Write-Host "Updating routes..." -ForegroundColor Yellow
$appRoutesTs = @'
import { Routes } from '@angular/router';
import { LoginComponent } from './components/login/login.component';
import { CourseBrowserComponent } from './components/course-browser/course-browser.component';
import { authGuard } from './guards/auth.guard';

export const routes: Routes = [
  { path: '', redirectTo: '/login', pathMatch: 'full' },
  { path: 'login', component: LoginComponent },
  { 
    path: 'courses', 
    component: CourseBrowserComponent,
    canActivate: [authGuard]
  },
  { path: '**', redirectTo: '/login' }
];
'@
$appRoutesTs | Out-File -FilePath "src\app\app.routes.ts" -Encoding UTF8
Write-Host "[OK] app.routes.ts" -ForegroundColor Green

# ============================================================
# 8. LOGIN COMPONENT
# ============================================================
Write-Host "Updating login component..." -ForegroundColor Yellow

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
      error: () => {
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
        <small>Default: <strong>admin</strong> / <strong>admin123</strong></small>
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
Write-Host "[OK] Login component" -ForegroundColor Green

Write-Host "`nContinue to create remaining components..." -ForegroundColor Yellow
Write-Host "Press Enter..." -ForegroundColor Cyan
$null = Read-Host


# ============================================================
# Continue from Part 1...
# This is Part 2 - Add to the same script or run separately
# ============================================================

# ============================================================
# 9. HEADER COMPONENT
# ============================================================
Write-Host "Updating header component..." -ForegroundColor Yellow

$headerComponentTs = @'
import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { AuthService } from '../../services/auth.service';
import { User } from '../../models/models';

@Component({
  selector: 'app-header',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './header.component.html',
  styleUrls: ['./header.component.scss']
})
export class HeaderComponent {
  currentUser: User | null = null;

  constructor(
    private authService: AuthService,
    private router: Router
  ) {
    this.authService.currentUser$.subscribe(user => {
      this.currentUser = user;
    });
  }

  logout(): void {
    this.authService.logout();
    this.router.navigate(['/login']);
  }
}
'@
$headerComponentTs | Out-File -FilePath "src\app\components\header\header.component.ts" -Encoding UTF8

$headerComponentHtml = @'
<header class="header">
  <div class="header-left">
    <h1>📚 LMS System</h1>
  </div>
  
  <div class="header-right">
    <span class="user-name" *ngIf="currentUser">
      👤 {{ currentUser.username }}
    </span>
    <button class="logout-btn" (click)="logout()">Logout</button>
  </div>
</header>
'@
$headerComponentHtml | Out-File -FilePath "src\app\components\header\header.component.html" -Encoding UTF8

$headerComponentScss = @'
.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 15px 30px;
  background: #2c3e50;
  color: white;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);

  h1 {
    margin: 0;
    font-size: 1.5em;
  }

  .header-right {
    display: flex;
    align-items: center;
    gap: 20px;
  }

  .user-name {
    font-size: 14px;
  }

  .logout-btn {
    padding: 8px 20px;
    background: #e74c3c;
    color: white;
    border: none;
    border-radius: 5px;
    cursor: pointer;
    font-size: 14px;
    transition: background 0.3s;

    &:hover {
      background: #c0392b;
    }
  }
}
'@
$headerComponentScss | Out-File -FilePath "src\app\components\header\header.component.scss" -Encoding UTF8
Write-Host "[OK] Header component" -ForegroundColor Green

# ============================================================
# 10. SIDEBAR COMPONENT
# ============================================================
Write-Host "Updating sidebar component..." -ForegroundColor Yellow

$sidebarComponentTs = @'
import { Component, Input, Output, EventEmitter } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Category } from '../../models/models';

@Component({
  selector: 'app-sidebar',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './sidebar.component.html',
  styleUrls: ['./sidebar.component.scss']
})
export class SidebarComponent {
  @Input() categories: Category[] = [];
  @Output() categorySelected = new EventEmitter<number | null>();
  
  selectedCategoryId: number | null = null;

  selectCategory(categoryId: number | null): void {
    this.selectedCategoryId = categoryId;
    this.categorySelected.emit(categoryId);
  }
}
'@
$sidebarComponentTs | Out-File -FilePath "src\app\components\sidebar\sidebar.component.ts" -Encoding UTF8

$sidebarComponentHtml = @'
<div class="sidebar">
  <div class="sidebar-section">
    <h3>Categories</h3>
    
    <div 
      class="category-item" 
      [class.active]="selectedCategoryId === null"
      (click)="selectCategory(null)">
      <span class="icon">🏠</span>
      <span>All Courses</span>
    </div>
    
    <div 
      *ngFor="let category of categories" 
      class="category-item"
      [class.active]="selectedCategoryId === category.id"
      (click)="selectCategory(category.id)">
      <span class="icon">{{ category.icon }}</span>
      <span>{{ category.name }}</span>
    </div>
  </div>
</div>
'@
$sidebarComponentHtml | Out-File -FilePath "src\app\components\sidebar\sidebar.component.html" -Encoding UTF8

$sidebarComponentScss = @'
.sidebar {
  width: 250px;
  background: #34495e;
  color: white;
  padding: 20px 0;
  overflow-y: auto;

  h3 {
    padding: 0 20px;
    margin-bottom: 15px;
    font-size: 14px;
    text-transform: uppercase;
    color: #95a5a6;
  }

  .category-item {
    padding: 12px 20px;
    cursor: pointer;
    display: flex;
    align-items: center;
    gap: 10px;
    transition: background 0.2s;

    &:hover {
      background: rgba(255,255,255,0.1);
    }

    &.active {
      background: #3498db;
      border-left: 4px solid #2ecc71;
    }

    .icon {
      font-size: 1.2em;
    }
  }
}
'@
$sidebarComponentScss | Out-File -FilePath "src\app\components\sidebar\sidebar.component.scss" -Encoding UTF8
Write-Host "[OK] Sidebar component" -ForegroundColor Green

# ============================================================
# 11. COURSE BROWSER COMPONENT
# ============================================================
Write-Host "Updating course browser component..." -ForegroundColor Yellow

$courseBrowserTs = @'
import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HeaderComponent } from '../header/header.component';
import { SidebarComponent } from '../sidebar/sidebar.component';
import { CourseService } from '../../services/course.service';
import { Course, Category } from '../../models/models';

@Component({
  selector: 'app-course-browser',
  standalone: true,
  imports: [CommonModule, HeaderComponent, SidebarComponent],
  templateUrl: './course-browser.component.html',
  styleUrls: ['./course-browser.component.scss']
})
export class CourseBrowserComponent implements OnInit {
  courses: Course[] = [];
  categories: Category[] = [];
  selectedCategory: number | null = null;
  loading = true;

  constructor(private courseService: CourseService) {}

  ngOnInit(): void {
    this.loadCategories();
    this.loadCourses();
  }

  loadCategories(): void {
    this.courseService.getCategories().subscribe({
      next: (categories) => {
        this.categories = categories;
      },
      error: (err) => console.error('Error loading categories:', err)
    });
  }

  loadCourses(): void {
    this.loading = true;
    if (this.selectedCategory) {
      this.courseService.getCoursesByCategory(this.selectedCategory).subscribe({
        next: (courses) => {
          this.courses = courses;
          this.loading = false;
        },
        error: (err) => {
          console.error('Error loading courses:', err);
          this.loading = false;
        }
      });
    } else {
      this.courseService.getAllCourses().subscribe({
        next: (courses) => {
          this.courses = courses;
          this.loading = false;
        },
        error: (err) => {
          console.error('Error loading courses:', err);
          this.loading = false;
        }
      });
    }
  }

  filterByCategory(categoryId: number | null): void {
    this.selectedCategory = categoryId;
    this.loadCourses();
  }

  openCourse(courseId: number): void {
    alert(`Opening course ${courseId} - Course viewer coming soon!`);
  }

  formatDuration(seconds: number): string {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    return hours > 0 ? `${hours}h ${minutes}m` : `${minutes}m`;
  }
}
'@
$courseBrowserTs | Out-File -FilePath "src\app\components\course-browser\course-browser.component.ts" -Encoding UTF8

$courseBrowserHtml = @'
<div class="app-container">
  <app-header></app-header>
  
  <div class="main-content">
    <app-sidebar 
      [categories]="categories" 
      (categorySelected)="filterByCategory($event)">
    </app-sidebar>
    
    <div class="content-area">
      <div class="breadcrumb">
        <span>🏠 Home</span>
        <span *ngIf="selectedCategory"> > Category</span>
      </div>
      
      <h1>📚 All Courses</h1>
      
      <div *ngIf="loading" class="loading">
        <div class="spinner"></div>
        <p>Loading courses...</p>
      </div>
      
      <div *ngIf="!loading && courses.length === 0" class="no-courses">
        <p>📭 No courses found</p>
        <small>Add courses by scanning your file system from the admin panel</small>
      </div>
      
      <div class="courses-grid" *ngIf="!loading && courses.length > 0">
        <div class="course-card" *ngFor="let course of courses" (click)="openCourse(course.id)">
          <div class="course-icon">🎓</div>
          <h3>{{ course.title }}</h3>
          <p>{{ course.description || 'No description available' }}</p>
          <div class="course-meta">
            <span>📝 {{ course.total_lessons }} lessons</span>
            <span>⏱️ {{ formatDuration(course.total_duration) }}</span>
          </div>
        </div>
      </div>
    </div>
  </div>
</div>
'@
$courseBrowserHtml | Out-File -FilePath "src\app\components\course-browser\course-browser.component.html" -Encoding UTF8

$courseBrowserScss = @'
.app-container {
  display: flex;
  flex-direction: column;
  height: 100vh;
}

.main-content {
  display: flex;
  flex: 1;
  overflow: hidden;
}

.content-area {
  flex: 1;
  padding: 20px 30px;
  overflow-y: auto;
  background: #ecf0f1;
}

.breadcrumb {
  color: #7f8c8d;
  margin-bottom: 20px;
  font-size: 14px;

  span {
    margin-right: 5px;
  }
}

h1 {
  margin-bottom: 30px;
  color: #2c3e50;
}

.loading {
  text-align: center;
  padding: 60px 20px;
  
  .spinner {
    border: 4px solid #f3f3f3;
    border-top: 4px solid #3498db;
    border-radius: 50%;
    width: 50px;
    height: 50px;
    animation: spin 1s linear infinite;
    margin: 0 auto 20px;
  }
  
  p {
    color: #7f8c8d;
  }
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.no-courses {
  text-align: center;
  padding: 60px 20px;
  color: #7f8c8d;
  
  p {
    font-size: 1.2em;
    margin-bottom: 10px;
  }
}

.courses-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  gap: 25px;
}

.course-card {
  background: white;
  border-radius: 12px;
  padding: 25px;
  cursor: pointer;
  transition: all 0.3s ease;
  box-shadow: 0 2px 8px rgba(0,0,0,0.08);
  border: 1px solid #e1e8ed;

  &:hover {
    transform: translateY(-8px);
    box-shadow: 0 8px 20px rgba(0,0,0,0.15);
    border-color: #3498db;
  }

  .course-icon {
    font-size: 3.5em;
    margin-bottom: 15px;
    text-align: center;
  }

  h3 {
    margin: 10px 0;
    color: #2c3e50;
    font-size: 1.3em;
  }

  p {
    color: #7f8c8d;
    font-size: 14px;
    margin-bottom: 20px;
    line-height: 1.5;
    min-height: 40px;
  }

  .course-meta {
    display: flex;
    justify-content: space-between;
    font-size: 13px;
    color: #95a5a6;
    padding-top: 15px;
    border-top: 1px solid #ecf0f1;
  }
}
'@
$courseBrowserScss | Out-File -FilePath "src\app\components\course-browser\course-browser.component.scss" -Encoding UTF8
Write-Host "[OK] Course browser component" -ForegroundColor Green

# ============================================================
# 12. GLOBAL STYLES
# ============================================================
Write-Host "Updating global styles..." -ForegroundColor Yellow
$stylesScss = @'
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
  background: #ecf0f1;
  color: #2c3e50;
}

html, body {
  height: 100%;
}
'@
$stylesScss | Out-File -FilePath "src\styles.scss" -Encoding UTF8
Write-Host "[OK] Global styles" -ForegroundColor Green

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "  ALL FILES UPDATED!" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Green

Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Start backend (if not running):" -ForegroundColor White
Write-Host "   cd C:\Projects\LMS-System\backend" -ForegroundColor Yellow
Write-Host "   uvicorn app.main:app --reload" -ForegroundColor Yellow
Write-Host "`n2. Start frontend:" -ForegroundColor White
Write-Host "   cd C:\Projects\LMS-System\frontend" -ForegroundColor Yellow
Write-Host "   ng serve" -ForegroundColor Yellow
Write-Host "`n3. Open browser:" -ForegroundColor White
Write-Host "   http://localhost:4200" -ForegroundColor Yellow
Write-Host "`n4. Login with:" -ForegroundColor White
Write-Host "   Username: admin" -ForegroundColor Yellow
Write-Host "   Password: admin123" -ForegroundColor Yellow
Write-Host "`n========================================`n" -ForegroundColor Cyan
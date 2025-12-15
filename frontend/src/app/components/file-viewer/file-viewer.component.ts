import { Component, Input, OnInit, OnChanges, SimpleChanges } from '@angular/core';
import { CommonModule } from '@angular/common';
import { LessonNode } from '../../models/models';

@Component({
  selector: 'app-file-viewer',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './file-viewer.component.html',
  styleUrls: ['./file-viewer.component.scss']
})
export class FileViewerComponent implements OnInit, OnChanges {
  @Input() lesson: LessonNode | null = null;
  @Input() playbackRate: number = 1;
  @Input() onPrev: () => void = () => {};
  @Input() onNext: () => void = () => {};
  
  videoElement: HTMLVideoElement | null = null;
  audioElement: HTMLAudioElement | null = null;
  currentTime: number = 0;
  duration: number = 0;
  volume: number = 1;
  isPlaying: boolean = false;

  ngOnInit(): void {
    this.loadResumePosition();
  }

  ngOnChanges(changes: SimpleChanges): void {
    if (changes['lesson'] && this.lesson) {
      this.loadResumePosition();
    }
    if (changes['playbackRate']) {
      this.updatePlaybackRate();
    }
  }

  onVideoLoaded(event: Event): void {
    this.videoElement = event.target as HTMLVideoElement;
    this.videoElement.playbackRate = this.playbackRate;
    this.videoElement.volume = this.volume;
    this.loadResumePosition();
    this.updateDuration();
  }

  onAudioLoaded(event: Event): void {
    this.audioElement = event.target as HTMLAudioElement;
    this.audioElement.playbackRate = this.playbackRate;
    this.audioElement.volume = this.volume;
    this.loadResumePosition();
    this.updateDuration();
  }

  onTimeUpdate(event: Event): void {
    const element = event.target as HTMLMediaElement;
    this.currentTime = element.currentTime;
    this.saveResumePosition();
  }

  onDurationChange(event: Event): void {
    this.updateDuration();
  }

  onPlayPause(): void {
    if (this.videoElement) {
      if (this.videoElement.paused) {
        this.videoElement.play();
        this.isPlaying = true;
      } else {
        this.videoElement.pause();
        this.isPlaying = false;
      }
    } else if (this.audioElement) {
      if (this.audioElement.paused) {
        this.audioElement.play();
        this.isPlaying = true;
      } else {
        this.audioElement.pause();
        this.isPlaying = false;
      }
    }
  }

  onVolumeChange(event: Event): void {
    const value = parseFloat((event.target as HTMLInputElement).value);
    this.volume = value;
    if (this.videoElement) this.videoElement.volume = value;
    if (this.audioElement) this.audioElement.volume = value;
  }

  onSeek(event: Event): void {
    const value = parseFloat((event.target as HTMLInputElement).value);
    if (this.videoElement) {
      this.videoElement.currentTime = value;
      this.currentTime = value;
    }
    if (this.audioElement) {
      this.audioElement.currentTime = value;
      this.currentTime = value;
    }
  }

  changePlaybackRate(rate: number): void {
    this.playbackRate = rate;
    this.updatePlaybackRate();
  }

  updatePlaybackRate(): void {
    if (this.videoElement) this.videoElement.playbackRate = this.playbackRate;
    if (this.audioElement) this.audioElement.playbackRate = this.playbackRate;
  }

  updateDuration(): void {
    if (this.videoElement) this.duration = this.videoElement.duration || 0;
    if (this.audioElement) this.duration = this.audioElement.duration || 0;
  }

  formatTime(seconds: number): string {
    if (!seconds || isNaN(seconds)) return '0:00';
    const h = Math.floor(seconds / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    const s = Math.floor(seconds % 60);
    if (h > 0) {
      return `${h}:${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
    }
    return `${m}:${s.toString().padStart(2, '0')}`;
  }

  loadResumePosition(): void {
    if (!this.lesson) return;
    const key = `lesson_progress_${this.lesson.file_path}`;
    const saved = localStorage.getItem(key);
    if (saved) {
      const time = parseFloat(saved);
      if (!isNaN(time)) {
        setTimeout(() => {
          if (this.videoElement) {
            this.videoElement.currentTime = time;
            this.currentTime = time;
          }
          if (this.audioElement) {
            this.audioElement.currentTime = time;
            this.currentTime = time;
          }
        }, 100);
      }
    }
  }

  saveResumePosition(): void {
    if (!this.lesson) return;
    const key = `lesson_progress_${this.lesson.file_path}`;
    localStorage.setItem(key, this.currentTime.toString());
  }

  getFileUrl(): string {
    if (!this.lesson) return '';
    // Always serve files through backend API
    return `http://localhost:8000/api/files/${encodeURIComponent(this.lesson.file_path)}`;
  }
}


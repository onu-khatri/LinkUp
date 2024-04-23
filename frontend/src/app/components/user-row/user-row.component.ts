import { Component, EventEmitter, Input, OnInit, Output } from '@angular/core';
import { Experience } from 'src/app/models/experience.model';
import { Skill } from 'src/app/models/skill.model';
import { User } from 'src/app/models/user.model';
import { TokenStorageService } from 'src/app/services/token-storage.service';
import { UserService } from 'src/app/services/user.service';

@Component({
  selector: 'app-user-row',
  templateUrl: './user-row.component.html',
  styleUrls: ['./user-row.component.css']
})
export class UserRowComponent implements OnInit {
  @Input() user?: User;
  @Output() friendRequest = new EventEmitter();
  @Output() followRequest = new EventEmitter();
  isLoggedIn = false;
  headline = '';
  profilePicPath = '';
  experiences: Experience[] = [];
  skills: Skill[] = [];
  isRequestSent = false;
  isCurrentUserFriend = false;
  isCurrentUserFollowing = false;
  isFollowing = false;
  batchList: number[] = []

  constructor(private userService: UserService, private tokenStorageService: TokenStorageService) { }

  ngOnInit(): void {
    if (this.user) {
      this.isLoggedIn = this.tokenStorageService.loggedIn();
      this.profilePicPath = this.userService.getProfilePicPath(this.user);
      this.headline = this.userService.getHeadline(this.user);
      this.experiences = this.userService.getExperiences(this.user);
      this.skills = this.user.skills;
      this.isRequestSent = this.user.isRequestSentByCurrentUser || false;
      this.isCurrentUserFriend = this.user.isCurrentUserFriend || false;
      this.isFollowing = this.user.isFollowByCurrentUser || false;

      if(this.user.badgesList) {
        this.batchList = this.user.badgesList.split(',').map(t => parseInt(t, 10)).filter(t => t);
      }
    }
  }

  follow(){
    if(this.user)
      {
        this.followRequest.emit(this.user.id);
        this.isFollowing = true;
      }
  }


  addConnection() {
    if(this.user) {
      this.friendRequest.emit(this.user.id);
      this.isRequestSent = true;
    }
  }
}

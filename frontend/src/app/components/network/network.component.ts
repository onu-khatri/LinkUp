import { ChangeDetectorRef, Component, OnInit } from '@angular/core';
import { FormControl } from '@angular/forms';
import { ActivatedRoute } from '@angular/router';
import { FriendRequest } from 'src/app/models/friendRequest.model';
import { User } from 'src/app/models/user.model';
import { TokenStorageService } from 'src/app/services/token-storage.service';
import { UserService } from 'src/app/services/user.service';

@Component({
  selector: 'app-network',
  templateUrl: './network.component.html',
  styleUrls: ['./network.component.css']
})
export class NetworkComponent implements OnInit {
  isLoggedIn = false;
  myUser?: User; // Logged in user
  friends?: User[] = [];
  errorMsg = '';
  currentRole = new FormControl('');
  futureRole = new FormControl('');
  topUsers: User[] = [];
  lastSearch: {currentRole?: string, futurerole?: string} = {};
  sentRequests: FriendRequest[] = [];

  constructor(private route: ActivatedRoute, private tokenService: TokenStorageService, private userService: UserService,private chRef :ChangeDetectorRef) { }

  ngOnInit(): void {
    this.isLoggedIn = this.tokenService.loggedIn();
    this.getData();
    this.userService.topUser$.subscribe(users => {   
      this.topUsers = users || [];
      this.lastSearch = this.userService.lastSearch;
    });

    this.getUser();
  }

  clearTopUsers() {
    this.topUsers = [];
      this.lastSearch = this.userService.lastSearch = {};
      this.userService.topUserSub.next([]);
      this.currentRole.setValue('');
      this.futureRole.setValue('');
      window.localStorage.setItem('lastSearch', JSON.stringify({}));
  }

  landingTopUserSearch() {
    if(!this.userService.lastSearch.currentRole && !this.userService.lastSearch.futureRole) {
      this.userService.getTopUserSearchFromStorage();
    }

    if(this.userService.lastSearch.currentRole || this.userService.lastSearch.futureRole) {
      this.currentRole.setValue(this.userService.lastSearch.currentRole);
      this.futureRole.setValue(this.userService.lastSearch.futureRole);

      this.searchTopUsers();
    }
  }

  getUser(): void {
    if (this.isLoggedIn) {
      this.userService.getUserProfile().subscribe(user => {
        this.myUser = user;
        this.landingTopUserSearch();
      });
    }
  }

  sendRequest(id: number): void {
    this.userService.sendFriendRequest(id).subscribe(request => {
      const user = this.topUsers.find(t => t.id == id);
      if(user)
        user.isRequestSentByCurrentUser = true;
    });
  }


  followRequest(id: number): void {
    if(this.myUser) {
    this.userService.followRequest(this.myUser.id, id).subscribe(request => {
      const user = this.topUsers.find(t => t.id == id);
      if(user)
        user.isFollowByCurrentUser = true;
    });
  }
  }

  searchTopUsers() {
    const currentRoleValue = this.currentRole.value;
    const futureRoleValue = this.futureRole.value;

      this.userService.getTopUsers(currentRoleValue, futureRoleValue, false, this.myUser?.id).subscribe(() => {
        
      });
  }

  getData(): void {
    if (this.isLoggedIn) {
      const id = this.route.snapshot.paramMap.get('id');
      if (id) {
        this.userService.getFriends(Number(id)).subscribe(friends => {
          this.friends = friends.map(t => {
            t.isCurrentUserFriend = true;
            return t;
          });
        }, this.handleError);
      } else {
        this.userService.getFriends().subscribe(friends => {
          this.friends = friends.map(t => {
            t.isCurrentUserFriend = true;
            return t;
          });
        }, this.handleError);
      }
    }
  }

  handleError(err: any): void {
    if (err.status === 403) {
      this.errorMsg = "Connection list of not connected professionals not available."
    } else {
      this.errorMsg = err.message;
    }
  }

}

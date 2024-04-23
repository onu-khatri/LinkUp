import { Component, OnInit } from '@angular/core';
import { FormControl } from '@angular/forms';
import { ActivatedRoute, NavigationEnd, Router } from '@angular/router';
import { filter } from 'rxjs/operators';
import { User } from 'src/app/models/user.model';
import { TokenStorageService } from 'src/app/services/token-storage.service';
import { UserService } from 'src/app/services/user.service';

@Component({
  selector: 'app-navbar',
  templateUrl: './navbar.component.html',
  styleUrls: ['./navbar.component.css']
})
export class NavbarComponent implements OnInit {
  isLoggedIn = false;
  currentUser?: User;
  profilePicPath?: string;
  searchBox = new FormControl('');
  currentRole = new FormControl('');
  futureRole = new FormControl('');
  isRegisterOrLoginPage = false;
  notificationsCount = 0;

  constructor(private tokenStorageService: TokenStorageService, private usersService: UserService, private router: Router) {
    this.router.events.pipe(filter(e => e instanceof NavigationEnd)).subscribe(e => {
      this.init();
      const url = this.router.routerState.snapshot.url.toLowerCase();
      this.isRegisterOrLoginPage =  url.indexOf('register') > -1 || url.indexOf('login') > -1
    });
  }

  ngOnInit(): void {
  }

  init() {
    this.isLoggedIn = this.tokenStorageService.loggedIn();
    this.getUser();
    this.getBadgeCounts();
  }

  searchTopUsers() {
    if(this.isRegisterOrLoginPage) {
    this.router.navigate(['/']).then(() => {
      this.callTopUsers();
    });
  } else {
    this.callTopUsers();
  }    
  }

  callTopUsers() {
    const currentRoleValue = this.currentRole.value;
    const futureRoleValue = this.futureRole.value;

    this.usersService.getTopUsers(currentRoleValue, futureRoleValue, false, this.currentUser?.id).subscribe();
  }

  getUser() {
    if (this.isLoggedIn) {
      this.usersService.getUserProfile().subscribe(user => {
        this.currentUser = user;
        this.profilePicPath = this.usersService.getProfilePicPath(user);
      });
    }
  }

  getBadgeCounts(): void {
    this.notificationsCount = 0;
    if (this.isLoggedIn) {
      this.usersService.getReceivedFriendRequests().subscribe(requests => {
        this.notificationsCount += requests.length;
      });
      this.usersService.getNotifications().subscribe(notifications => {
        this.notificationsCount += notifications.filter(n => n.read === false).length;
      });
    }
  }

  search(): void {
    if (this.searchBox.value) {
      this.router.navigate(['/search'], { queryParams: { q: this.searchBox.value } });
    }
  }

  logout() {
    this.tokenStorageService.signOut();
    window.location.reload();
  }
}

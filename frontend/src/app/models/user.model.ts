import { Education } from "./education.model";
import { Experience } from "./experience.model";
import { Skill } from "./skill.model";

export enum UserRole {
    Admin = 'a',
    Professional = 'p'
}

export interface User {
    id: number;
    firstname: string;
    lastname: string;
    email: string;
    phone: string;
    role: UserRole;
    profilePicName: string;
    skills: Skill[];
    educations: Education[];
    experiences: Experience[];
    followerAdded: Experience[];
    isCurrentUserFriend?: boolean;
    isRequestSentByCurrentUser?: boolean; 
    isFollowByCurrentUser?: boolean;
    following?: {id: number}[];
    LeaderShipScore?: number;
    articalLikeCounts?: number;
    articalcounts?: number;
    followCount?: number;
    jobcounts?: number;
    skillcounts?: number;
    badgesList?: string;
}
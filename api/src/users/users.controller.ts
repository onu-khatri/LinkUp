import { Body, Controller, Get, Param, Post, Put, UseGuards, UseInterceptors, Request, Delete, ForbiddenException, Patch, UploadedFile, BadRequestException, Query } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { JwtAuthGuard } from 'src/auth/guards/jwt-auth.guard';
import { EducationDto } from './dto/education.dto';
import { AddSkillsDto } from './dto/add-skills.dto';
import { ChangePasswordAdminDto } from './dto/change-password-admin.dto';
import { ChangePasswordDto } from './dto/change-password.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { FriendRequestSameReceiverGuard } from './guards/friend-request-same-receiver.guard';
import { FriendRequestSameSenderGuard } from './guards/friend-request-same-sender.guard';
import { NotificationReceiverGuard } from './guards/notification-receiver.guard';
import { OnlyAdminsGuard } from './guards/only-admins.guard';
import { OnlyFriendsGuard } from './guards/only-friends.guard';
import { profilePicOptions } from './helpers/profile-pic-storage';
import { HidePasswordInterceptor } from './interceptors/hide-password.interceptor';
import { UsersService } from './users.service';
import { EducationOwnerGuard } from './guards/education-owner.guard';
import { ExperienceDto } from './dto/experience.dto';
import { ExperienceOwnerGuard } from './guards/experience-owner.guard';
import { ExportUsersDto } from './dto/export-users.dto';
import { VisibilitySettingsDto } from './dto/visibility-settings.dto';
import { UserInfoVisibilityIntercepretor } from './interceptors/user-info-visibility.intercepretor';

@UseInterceptors(HidePasswordInterceptor)
@Controller('users')
export class UsersController {
    constructor(private readonly usersService : UsersService) {}

    // Basic Functionality
    @Get('topusers')
    async findTopRoles(@Query('currentRole') currentRole: string, @Query('futureRole') futureRole: string, @Query('userId') userId: string) {
        return await this.usersService.findTopUsers(currentRole, futureRole, parseInt(userId, 10));
    }

    @UseGuards(JwtAuthGuard)
    @UseInterceptors(UserInfoVisibilityIntercepretor)
    @Get()
    async findAll(@Query('q') q: string) {
        return await this.usersService.find(q);
    }

    @UseGuards(JwtAuthGuard, OnlyAdminsGuard)
    @Post('export')
    exportUsers(@Body() exportUsersDto: ExportUsersDto) {
        return this.usersService.findSome(exportUsersDto.ids);
    }

    
    @UseGuards(JwtAuthGuard)
    @Get('visibilitySettings')
    getVisibilitySettings(@Request() req) {
        return this.usersService.getVisibilitySettings(+req.user.id);
    }

    @UseGuards(JwtAuthGuard)
    @Post('visibilitySettings')
    updateVisibilitySettings(@Request() req, @Body() visibilitySettingsDto: VisibilitySettingsDto) {
        return this.usersService.updateVisibilitySettings(+req.user.id, visibilitySettingsDto);
    }

    @UseGuards(JwtAuthGuard)
    @UseInterceptors(UserInfoVisibilityIntercepretor)
    @Get(':id')
    findOne(@Param('id') id: string) {
        return this.usersService.findOne(+id);
    }

    @UseGuards(JwtAuthGuard)
    @Put()
    updateMe(@Request() req, @Body() updateUserDto: UpdateUserDto) {
        return this.usersService.update(+req.user.id, updateUserDto);
    }

    @UseGuards(JwtAuthGuard, OnlyAdminsGuard)
    @Put(':id')
    update(@Param('id') id: string, @Body() updateUserDto: UpdateUserDto) {
        return this.usersService.update(+id, updateUserDto);
    }

    @UseGuards(JwtAuthGuard)
    @Patch('change-password')
    async changeMyPassword(@Request() req, @Body() changePasswordDto: ChangePasswordDto) {
        const userWithPassword = await this.usersService.findLoginUser(req.user.email);
        const passOk = await this.usersService.checkPassword(userWithPassword, changePasswordDto.oldPassword);
        if (passOk) {
            return this.usersService.changePassword(userWithPassword.id,changePasswordDto.newPassword);
        } else {
            throw new ForbiddenException("Wrong Password!");
        }
    }

    @UseGuards(JwtAuthGuard, OnlyAdminsGuard)
    @Patch('change-password/:id')
    async changePassword(@Param('id') id: string, @Body() changePasswordDto: ChangePasswordAdminDto) {
        return this.usersService.changePassword(+id,changePasswordDto.newPassword);
    }

    @UseGuards(JwtAuthGuard)
    @Delete()
    deleteMe(@Request() req) {
        return this.usersService.delete(+req.user.id);
    }

    @UseGuards(JwtAuthGuard, OnlyAdminsGuard)
    @Delete(':id')
    delete(@Param('id') id: string) {
        return this.usersService.delete(+id);
    }

    @UseGuards(JwtAuthGuard)
    @Post('profile-pic')
    @UseInterceptors(FileInterceptor('pic', profilePicOptions))
    changeProfilePic(@UploadedFile() pic: Express.Multer.File, @Request() req) {
        if (pic) {
            return this.usersService.changeProfilePic(+req.user.id, pic.filename);
        } else {
            throw new BadRequestException("Incorrect image type.");
        }
    }

    @UseGuards(JwtAuthGuard)
    @Delete('profile-pic/delete') 
    deleteProfilePic(@Request() req) {
        return this.usersService.deleteProfilePic(+req.user.id);
    }

    // Friend Requests

    @UseGuards(JwtAuthGuard)
    @Get('friend-requests/sent')
    getSentFriendRequests(@Request() req) {
        return this.usersService.getSentFriendRequests(+req.user.id);
    }

    @UseGuards(JwtAuthGuard)
    @Get('friend-requests/received')
    getReceivedFriendRequests(@Request() req) {
        return this.usersService.getReceivedFriendRequests(+req.user.id);
    }

    @UseGuards(JwtAuthGuard)
    @Post('friend-requests/send/:receiver')
    sendFriendRequest(@Request() req, @Param('receiver') receiver: string) {
        return this.usersService.sendFriendRequest(req.user,+receiver);
    }

    @UseGuards(JwtAuthGuard, FriendRequestSameSenderGuard)
    @Delete('friend-requests/cancel/:id')
    cancelFriendRequest(@Param('id') id: string) {
        return this.usersService.cancelFriendRequest(+id);
    }

    @UseGuards(JwtAuthGuard, FriendRequestSameReceiverGuard)
    @Post('friend-requests/accept/:id')
    acceptFriendRequest(@Param('id') id: string) {
        return this.usersService.acceptFriendRequest(+id);
    }

    @UseGuards(JwtAuthGuard, FriendRequestSameReceiverGuard)
    @Post('friend-requests/decline/:id')
    declineFriendRequest(@Param('id') id: string) {
        return this.usersService.declineFriendRequest(+id);
    }

    // Friendships

    @UseGuards(JwtAuthGuard)
    @Get('friends/mine')
    getMyFriends(@Request() req) {
        return this.usersService.getFriends(+req.user.id);
    }

    @UseGuards(JwtAuthGuard, OnlyFriendsGuard)
    @UseInterceptors(UserInfoVisibilityIntercepretor)
    @Get('friends/:id')
    getFriends(@Param('id') id: string) {
        return this.usersService.getFriends(+id);
    }

    @UseGuards(JwtAuthGuard)
    @Delete('friends/:id')
    removeFriend(@Request() req, @Param('id') id: string) {
        return this.usersService.removeFriend(req.user.id, +id);
    }

    // Notifications

    @UseGuards(JwtAuthGuard)
    @Get('notifications/all')
    getNotifications(@Request() req) {
        return this.usersService.getUserNotifications(+req.user.id);
    }

    @UseGuards(JwtAuthGuard, NotificationReceiverGuard)
    @Post('notifications/read/:id')
    readNotification(@Param('id') id: string) {
        return this.usersService.readNotification(+id);
    }

    // Skills

    @UseGuards(JwtAuthGuard)
    @Post('skills')
    addSkills(@Request() req, @Body() addSkillsDto: AddSkillsDto) {
        return this.usersService.addSkills(+req.user.id, addSkillsDto.skills);
    }

    @UseGuards(JwtAuthGuard)
    @Delete('skills/:id')
    removeSkill(@Request() req, @Param('id') id: string) {
        return this.usersService.removeSkillFromUser(+req.user.id, +id);
    }

    // Education

    @UseGuards(JwtAuthGuard)
    @Post('education')
    addEducation(@Request() req, @Body() educationDto: EducationDto) {
        return this.usersService.addEducation(+req.user.id, educationDto);
    }

    @UseGuards(JwtAuthGuard, EducationOwnerGuard)
    @Put('education/:id')
    updateEducation(@Body() educationDto: EducationDto, @Param('id') id: string) {
        return this.usersService.updateEducation(+id, educationDto);
    }

    @UseGuards(JwtAuthGuard)
    @Delete('education/:id')
    removeEducation(@Request() req, @Param('id') id: string) {
        return this.usersService.removeEducation(+req.user.id, +id);
    }

    // Experience

    @UseGuards(JwtAuthGuard)
    @Post('experience')
    addExperience(@Request() req, @Body() experienceDto: ExperienceDto) {
        return this.usersService.addExperience(+req.user.id, experienceDto);
    }

    @UseGuards(JwtAuthGuard, ExperienceOwnerGuard)
    @Put('experience/:id')
    updateExperience(@Body() experienceDto: ExperienceDto, @Param('id') id: string) {
        return this.usersService.updateExperience(+id, experienceDto);
    }

    @UseGuards(JwtAuthGuard)
    @Delete('experience/:id')
    removeExperience(@Request() req, @Param('id') id: string) {
        return this.usersService.removeExperience(+req.user.id, +id);
    }

    @UseGuards(JwtAuthGuard)
    @Post('follow-requests/:userId1/:userId2')
    followUser(@Request() req, @Param('userId1') userId1: number, @Param('userId2') userId2: number) {
        return this.usersService.newFollowing(userId1, userId2);
    }
}

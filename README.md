# LinkUp
A project to show how a talent pool can used as a networking site. This shows how people can connect to grow with a self-taught spirit and help each other.

The app was developed using [Angular](https://angular.io/) for the frontend, [NestJs](https://nestjs.com/) for the backend, and [PostgreSQL](https://www.postgresql.org/) for the database. 

To install you just need to do the following:
- Install [NodeJs and npm](https://nodejs.org/en/), and PostgreSQL
- Restore database using LinUp_Database.sql
- Navigate to the API folder which contains the backend and install the node modules by running `npm install`
- Navigate to the frontend folder and install the node modules by running `npm install`
- Navigate to the `api/ormconfig.json` file and configure the database connectivity options.
- Navigate to the `SSL` and install the certificate which is for localhost or you can create your own and replace the corresponding files.

To run the application you just need to:
- Run the backend by going to the `API` folder and then run the command `npm run start`
- Run the frontend by going to the `frontend` folder and then run the command `npm start`
- Navigate to https://localhost:4200.
  
## Development server
Run `ng serve` for a dev server. Navigate to `http://localhost:4200/`. The app will automatically reload if you change any of the source files.

## Build
Run `ng build` to build the project. The build artifacts will be stored in the `dist/` directory.

---------------------------------------------------------------------

The project also contains 100 fake faces for user profile

Provided by, Alexander Reben, ANTEPOSSIBLE LLC
http://www.areben.com
@artBoffin

Licensed under Creative Commons Attribution-NonCommercial 4.0 International
---
Content generated from StyleGAN algorithm and model licensed under CC BY-NC 4.0 by NVIDIA CORPORATION

A Style-Based Generator Architecture for Generative Adversarial Networks
Tero Karras (NVIDIA), Samuli Laine (NVIDIA), Timo Aila (NVIDIA)
http://stylegan.xyz/paper

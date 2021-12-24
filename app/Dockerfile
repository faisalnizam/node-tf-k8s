FROM node:16 as build-deps

WORKDIR /usr/src/app

COPY package.json yarn.lock ./

COPY . .

RUN npm install 

EXPOSE 3000

CMD ["npm", "run", "dev"]


#FROM nginx:1.12-alpine
#COPY --from=build-deps /usr/src/app/ /usr/share/nginx/html
#EXPOSE 80
#CMD ["nginx", "-g", "daemon off;"]



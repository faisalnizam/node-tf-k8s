FROM node:16 as build-deps

WORKDIR /usr/src/app

COPY package.json yarn.lock ./

COPY . .

RUN npm install 

EXPOSE 3000

CMD ["npm", "run", "dev"]

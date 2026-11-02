FROM node:22 as build
WORKDIR /opt/app
ADD package*.json ./
RUN npm ci
ADD . .
RUN npm run build --prod

FROM node:22
WORKDIR /opt/app
COPY --from=build /opt/app/dist ./dist
ADD package*.json ./
RUN npm ci --omit=dev
CMD [ "node", "./dist/main.js" ]
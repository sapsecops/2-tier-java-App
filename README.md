# Before these Install required Tools for that refer Tools_setup.md 
## Clone the Repo
```
cd /home/ec2-user/
sudo git clone https://github.com/sapsecops/2-tier-java-App.git
```
## Switch to Local-Setup Branch
```
cd /home/ec2-user/2-tier-java-App
sudo git checkout 02-Docker-Setup
```
# Create network for our 2-Tier UMS Application
```
docker network create ums-net
```

# Build Image for  postgressql  DB

```
cd /home/ec2-user/2-tier-java-App/postgres
docker build -t sapsecops/2-tier-java:postgresv1 .
```

# Run postgresql Image
```
docker run -d \
  --name ums-db \
  --network ums-net \
  -e POSTGRES_USER=dbadmin \
  -e POSTGRES_PASSWORD=Admin@123 \
  -p 5432:5432 \
  -v pgdata:/var/lib/postgresql/data \
  sapsecops/2-tier-java:postgresv1
```
### Check your Tables and dummy data created or Not
```
docker exec -it ums-db psql -U dbadmin -d employeedb -c "select * from employee;"
```

## Build Image for  Java Application  DB

### Before that we need to Edit your DB credentials in application.properties file

```
cd /home/ec2-user/2-tier-java-App/java
sudo vim src/main/resources/application.properties
```
```
spring.datasource.url=jdbc:postgresql://<db-Container-Name>:5432/employeedb
spring.datasource.username=appuser
spring.datasource.password=P@55Word
spring.datasource.driver-class-name=org.postgresql.Driver
```
## Note => Replace DB_Hostname as your DB Container Name

If you get permission Issue

### Give the permissions
```
sudo chown -R ec2-user:ec2-user /home/ec2-user/2-tier-java-App
chmod u+w /home/ec2-user/2-tier-java-App
```
## Build the Artifact
```
mvn clean package
```
# Build the JAVA App Image
```
docker build -t sapsecops/2-tier-java:javaV1 --build-arg WAR_FILE=target/SSO-1.0-SNAPSHOT.war .
```


# Run JAVA Application Image
```
docker run -d \
  --name ums-app \
  --network ums-net \
  -p 8080:8080 \
  -e SPRING_DATASOURCE_URL=jdbc:postgresql://ums-db:5432/employeedb \
  -e SPRING_DATASOURCE_USERNAME=appuser \
  -e SPRING_DATASOURCE_PASSWORD=P@55Word \
  sapsecops/2-tier-java:javaV1
```

### Access Your App in Browser
```
http://<AWS-Public-IP>:8080/
```
<img width="668" height="319" alt="image" src="https://github.com/user-attachments/assets/36d5e632-8591-47b1-ba97-4804c21b47ef" />
<img width="625" height="673" alt="image" src="https://github.com/user-attachments/assets/deff83f2-da79-4561-a295-21899b8f510c" />
<img width="1024" height="484" alt="image" src="https://github.com/user-attachments/assets/b588ee23-0fd3-44c1-9b88-f8d0a04a6947" />

# Database Setup
## Create "t2.micro" EC2 Instance and open port "5432" for DB 

## Install postgressql  DB
```
sudo dnf update -y
sudo dnf install -y postgresql16-server
which postgresql-setup
```
Initialize the database
```
sudo /usr/bin/postgresql-setup --initdb
```
<img width="579" height="52" alt="image" src="https://github.com/user-attachments/assets/a703cae2-1f67-4e7f-8700-6219399d0021" />


```
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

## Setup postgressql DB

#### Allow Remote Host connect to DB
1. Edit the "postgresql.conf" file in path "/var/lib/pgsql/data/postgresql.conf"
```
sudo vim /var/lib/pgsql/data/postgresql.conf
```
ADD these Under connection settings
```
listen_addresses = '*'
```
<img width="301" height="155" alt="image" src="https://github.com/user-attachments/assets/a6f7607e-7611-4138-8162-d4f8894f0ae3" />

2. Edit the "pg_hba.conf" file in path "/var/lib/pgsql/data/pg_hba.conf"

```
sudo vim /var/lib/pgsql/data/pg_hba.conf
```
Edit IPV4 Local Connection Method from ident to md5 these lines 
```
# IPv4 local connections:
host    all             all             127.0.0.1/32            md5
```
ADD these lines 
```
# Allow remote user connections from a single IP
host    all             all             0.0.0.0/0          md5
```
<img width="572" height="68" alt="image" src="https://github.com/user-attachments/assets/73d36241-5e6c-4790-be9c-9e4ec3337805" />

Restart postgressql DB
```
sudo systemctl restart postgresql
```
# DB-Tier Setup
#### Create DB and User in database

Switch to postgres User
```
sudo -i -u postgres
```
Login to DB promt
```
psql
```
Change the Passordward for postgres User

```
ALTER USER postgres WITH PASSWORD 'NewStrongPasswordHere';
```

```
SELECT VERSION();
```

### Create one Databse Admin User for our DB
Create DnB admin user (role) with login password
```
CREATE ROLE dbadmin WITH LOGIN PASSWORD 'Admin@123';
```
Grant all privileges on all databases
```
GRANT ALL PRIVILEGES ON DATABASE postgres TO dbadmin;
```
Grant ability to create new databases and roles (similar to WITH GRANT OPTION)
```
ALTER ROLE dbadmin CREATEDB CREATEROLE SUPERUSER;
```



# Application server Setup
## Create "t2.micro" EC2 Instance and open port "8080" for Tomcat Applicaion Server

## Refer "Tools_setup.md" for Installing Required Tools Before execute these steps


### Install Git
```
sudo yum install git -y
```
#### To start this application first you can get the code using below url
##### Clone the Repo

```
cd /home/ec2-user/
sudo git clone https://github.com/sapsecops/2-tier-java-App.git
```
### Switch to Local-Setup Branch
```
cd /home/ec2-user/JAVA-2-tier-UMS-Local
sudo git checkout 01-Local-setup-Prod
```
## Setup your Application Database by executing "initdb.sql" script from Application-server

Step:1 ==> install "postgressql-Client" for communicate with MYSQL Database
```
sudo dnf update -y
sudo dnf install -y postgresql16
which postgresql-setup
```
Step:2 ==> Execute your "init.sql" script for your Application DB setup

```
PGPASSWORD="Admin@123" psql -h 172.31.16.207 -U dbadmin -d postgres -f initdb.sql
```
### Edit your DB credentials in application.properties file
```
sudo vim src/main/resources/application.properties
```
Edit HERE your DB and Host Details
```
spring.datasource.url=jdbc:postgresql://<DB-Private-IP>:5432/<Your-DB-Name>
spring.datasource.username=<User-name>
spring.datasource.password=<Password>
spring.datasource.driver-class-name=org.postgresql.Driver
```
If you get permission Issue

```
sudo chown -R ec2-user:ec2-user /home/ec2-user/JAVA-2-tier-UMS-Local
chmod u+w /home/ec2-user/JAVA-2-tier-UMS-Local
```

### Build the Artifact
```
mvn clean package
```

### Deploy these Artifact to Tomcat-Dev
```
sudo cp -r target/*.war /opt/tomcat/webapps
sudo mv /opt/tomcat/webapps/SSO-1.0-SNAPSHOT.war /opt/tomcat/webapps/SSO.war
```

### Access Your App in Browser
```
http://<AWS-Public-IP>:8080/SSO
```
<img width="668" height="319" alt="image" src="https://github.com/user-attachments/assets/36d5e632-8591-47b1-ba97-4804c21b47ef" />
<img width="625" height="673" alt="image" src="https://github.com/user-attachments/assets/deff83f2-da79-4561-a295-21899b8f510c" />
<img width="1024" height="484" alt="image" src="https://github.com/user-attachments/assets/b588ee23-0fd3-44c1-9b88-f8d0a04a6947" />


### To Run the Test
```
mvn test
```

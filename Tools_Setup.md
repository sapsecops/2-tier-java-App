
# LAB-Setup

```
Launch Ec2 Instance and use Amazon Linux 2 AMI with t2.micro Instance and 
open port "8080" in Seaurity Group for TOMCAT
```
# Tools Setup For the Project 

### Install JAVA
####  Installation of openJDK 17
```
sudo dnf update -y
sudo yum install java-17-amazon-corretto-devel -y
``` 

### Install Maven
```
sudo wget https://dlcdn.apache.org/maven/maven-3/3.9.11/binaries/apache-maven-3.9.11-bin.tar.gz
sudo tar xzf apache-maven-3.9.11-bin.tar.gz -C /opt
sudo ln -s apache-maven-3.9.11 /opt/maven
```
#### Create Profile for Maven  
```
sudo vi /etc/profile.d/maven.sh
```

```
export M2_HOME=/opt/maven
export PATH=${M2_HOME}/bin:${PATH}
```
#### Reload profile
```
sudo chmod +x /etc/profile.d/maven.sh
source /etc/profile.d/maven.sh
mvn -version
```


### Install Git
```
sudo yum install git docker -y
```
### Configure Docker
```
sudo systemctl start docker
sudo usermod -aG docker ec2-user
exit
```

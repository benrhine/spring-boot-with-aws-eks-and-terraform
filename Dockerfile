FROM amazoncorretto:17-alpine-jdk

# Copy local code to the container image.
WORKDIR /app
#COPY . .
COPY build/libs/spring-boot-with-aws-eks-and-terraform-0.0.1-SNAPSHOT.jar .

# Build a release artifact.
#RUN ./gradlew build -x test
RUN chmod +x spring-boot-with-aws-eks-and-terraform-0.0.1-SNAPSHOT.jar

# Run the web service on container startup.
#CMD ["java", "-jar", "/build/libs/kubernetes-example-0.0.1-SNAPSHOT.jar"]


ENTRYPOINT ["java","-jar","spring-boot-with-aws-eks-and-terraform-0.0.1-SNAPSHOT.jar"]



# https://www.baeldung.com/java-dockerize-app
# https://docs.docker.com/guides/java/containerize/
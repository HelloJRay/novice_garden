## SpringBoot程序Dockerfile样例

提供arm64和amd64平台的两个Dockerfile样例

### 一、Dockerfile arm64

```dockerfile
# 使用ARM架构的JDK 8作为基础镜像
FROM arm64v8/eclipse-temurin:8-jdk-jammy

# 设置工作目录
WORKDIR /ray-app

# 配置时区（可选）
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 创建非root用户（安全最佳实践）
# RUN useradd -ms /bin/bash springuser
# USER springuser

# 复制本地JAR文件到镜像中（假设JAR文件位于当前目录的target子目录下）
# COPY --chown=springuser:springuser target/com-ray-cost.jar /ray-app/com-ray-cost.jar
COPY target/ /ray-app/

# 优化ARM架构的JVM参数
ENV JAVA_OPTS="-Dlogging.config=/ray-app/config/logback-spring.xml \
                -Dfile.encoding=UTF-8 \
                -XX:+HeapDumpOnOutOfMemoryError \
                -XX:HeapDumpPath=/ray-app/logs/ray_app.dump \
                -XX:+UseContainerSupport \
                -XX:MaxRAMPercentage=75.0 \
                -XX:+UseG1GC \
                -Dapp.work.dir=/ray-app"

# 优化SPringBoot程序启动参数
ENV SPRING_OPTS="--debug"

# 健康检查端点 
HEALTHCHECK --interval=30s --timeout=3s CMD curl -f http://localhost:18188/actuator/health || exit 1

# 暴露Spring Boot默认端口
EXPOSE 18188

# 启动命令
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar /ray-app/com-ray-cost.jar $SPRING_OPTS"]
```

---

### 二、Dockerfile amd64(x86)

```dockerfile
# 使用官方x86架构的OpenJDK 1.8基础镜像
FROM eclipse-temurin:8-jdk-jammy

# 设置时区
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 创建非特权用户
RUN useradd -ms /bin/bash appuser && \
    mkdir -p /ray-app && \
    chown -R appuser:appuser /ray-app
USER appuser

# 构建上下文目录设置  设置工作目录
WORKDIR /ray-app
COPY --chown=appuser:appuser ./target/ /ray-app

# JVM参数
ENV JAVA_OPTS="-Djava.security.egd=file:/dev/./urandom \
               -Dlogging.config=/ray-app/config/logback-spring.xml \
               -Dfile.encoding=UTF-8 -XX:+HeapDumpOnOutOfMemoryError \
               -XX:HeapDumpPath=/ray-app/logs/ray_app.dump \
               -XX:+UseContainerSupport \
               -XX:MaxRAMPercentage=75.0 \
               -XX:+UseG1GC \
               -Dapp.work.dir=/ray-app"

# 优化SPringBoot程序启动参数
ENV SPRING_OPTS="--debug"

# 健康检查端点
HEALTHCHECK --interval=30s --timeout=3s CMD curl -f http://localhost:18188/actuator/health || exit 1

# 容器启动命令
EXPOSE 18188

# 启动命令
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar /ray-app/com-ray-cost.jar $SPRING_OPTS"]
```

---

### 三、Dockerfile样例后续说明

#### 3.1 Dockerfile使用说明

1. **文件结构要求**  
   将 `com-ray-app.jar` 放在与Dockerfile同级目录的 `target` 子目录中：
   
   ```
   ├── Dockerfile
   └── target/
       └── com-ray-app.jar
   ```

2. **构建镜像**  
   
   ```bash
   # 隐式但平台编译镜像，构建的系统架构以当前编译环境为主
   docker build -t com-ray-app:1.0 --platform linux/amd64 .
   # 显式指定单平台编译镜像
   docker build -t com-ray-app:1.0 --platform linux/arm64 .
   # 多平台交叉编译镜像
   docker buildx build --platform linux/amd64,linux/arm64 -t com-ray-app:1.0 .
   ```
   
   注： docker build 命令最后面有一个半角的点符号，表示当前目录，为必要参数。

3. **运行容器**  
   
   ```bash
   docker run -d \
     --platform linux/arm64 \
     -p 18183:18188\
     --memory=2g \
     --name com-ray-app \
     com-ray-app:1.0
   ```

        *注： 18183 为容器外宿主机上监听的端口号，18188为docker内监听的端口号*

---

#### 3.2 Dockerfile 关键配置说明

| 配置项         | 说明                                                         |
| ----------- | ---------------------------------------------------------- |
| **基础镜像**    | `arm64v8/eclipse-temurin:8-jdk-jammy` 官方ARM64 JDK8镜像       |
| **时区配置**    | 解决容器内时间与宿主机不一致问题（可删除`TZ`相关配置若不需时区同步）                       |
| **JVM参数优化** | `UseContainerSupport`自动适配容器内存限制，`UseG1GC`为ARM推荐垃圾回收器       |
| **非root用户** | 避免使用root权限运行容器，提升安全性                                       |
| **平台指定**    | `--platform linux/arm64` 确保在非ARM设备上构建时正确交叉编译（如macOS M系列芯片） |

---

#### 3.3 镜像验证方法

1. **检查容器架构**  
   
   ```bash
   docker exec com-ray-app uname -m
   # 应输出：aarch64
   ```

2. **查看JVM版本**  
   
   ```bash
   docker exec com-ray-app java -version
   # 应输出ARM架构的JDK8信息
   ```

3. **监控应用日志**  
   
   ```bash
   docker logs -f com-ray-app
   ```

---

#### 3.4 容器扩展配置建议

1. **健康检查**  
   添加HTTP健康检查（需应用实现健康检查端点）：
   
   ```dockerfile
   # 需要在pom中引用’spring-boot-starter-actuator‘并开启’health‘监控点，
   # 参考application.properties的配置：
   #    开启所有监控点：management.endpoints.web.exposure.include: "*"
   #    单独开放部分监控点：management.endpoints.web.exposure.include: beans,trace
   HEALTHCHECK --interval=30s --timeout=3s CMD curl -f http://localhost:8080/actuator/health || exit 1
   # 除了使用springboot官方的监控点集成方案，也可以自己实现或使用其它开源方案，同时修改Dockerfile中的’HEALTHCHECK‘配置即可。
   ```

2. **配置文件挂载**  
   若需要外部化配置，可挂载配置文件：
   
   ```bash
   docker run -v /path/to/config:/app/config com-ray-app:1.0
   ```

3. **性能监控**  
   添加JMX监控支持：
   
   ```dockerfile
   ENV JAVA_OPTS="$JAVA_OPTS -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=9010 -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false"
   EXPOSE 9010
   ```
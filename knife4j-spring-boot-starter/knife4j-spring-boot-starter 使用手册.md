## knife4j-spring-boot-starter 使用手册

### 一、pom引用

```xml
    <parent>
		<groupId>org.springframework.boot</groupId>
		<artifactId>spring-boot-starter-parent</artifactId>
		<version>2.7.15</version>
	</parent>
    ......
    <properties>
		<java.version>1.8</java.version>
		<project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
		<project.reporting.outputEncoding>UTF-8</project.reporting.outputEncoding>
    </properties>
    
    <dependencies>
        <dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-starter-web</artifactId>
		</dependency>
		<dependency>
			<groupId>com.github.xiaoymin</groupId>
			<artifactId>knife4j-spring-boot-starter</artifactId>
			<version>3.0.3</version>
		</dependency>
        ......
    </dependencies>
```



### 二、yml配置

```yml
# knife4j 官网参考文档：https://doc.xiaominfo.com/docs/features/enhance
# 访问地址 http://localhost:18181/doc.html#/home
knife4j:
  enable: true
  cors: false
  production: false
  # 开启动态请求参数，true-开启，false-关闭
  # enable-dynamic-parameter: true
  setting:
    language: zh-CN
    enableGroup: true
    enableFooter: false
    enableFooterCustom: false
    footerCustomContent: Copyright &copy; 这是一个XXX服务
```

### 三、java配置

1. **swagger Configuration**

```java
/**
 * swagger配置
 */
@Configuration
@EnableSwagger2
public class SwaggerConfig {
    /*引入Knife4j提供的扩展类*/
    private final OpenApiExtensionResolver openApiExtensionResolver;

    @Autowired
    public SwaggerConfig(OpenApiExtensionResolver openApiExtensionResolver) {
        this.openApiExtensionResolver = openApiExtensionResolver;
    }


    @Bean
    public Docket createAllRestApi(ApiInfo apiInfo) {
        return new Docket(DocumentationType.SWAGGER_2)
                .groupName(ApiConstant.GROUP_ALL)
                .apiInfo(apiInfo)
                .select()
                .apis(
                        // 这里改成自己的包目录 建议尽量精确 提升扫描速度
                        RequestHandlerSelectors.basePackage("com.XXX1.controller")
                                .or(RequestHandlerSelectors.basePackage("com.XXX2.controller"))
                                .or(RequestHandlerSelectors.basePackage("cn.XXX3.controller"))
                            .and(RequestHandlerSelectors.withClassAnnotation(Api.class))
                            .and(RequestHandlerSelectors.withMethodAnnotation(ApiOperation.class))
                )
                .paths(PathSelectors.any())
                .build()
                .globalRequestParameters(buildParameters())
                //赋予插件体系
                .extensions(openApiExtensionResolver.buildExtensions(ApiConstant.GROUP_ALL));
    }

//  可以返回多个‘Docket’实例，对API进行细致化分组
//    @Bean
//    public Docket  group2Api(ApiInfo apiInfo) {
//        return new Docket(DocumentationType.SWAGGER_2)
//                .groupName(ApiConstant.GROUP_2)
//                .apiInfo(apiInfo)
//                .select()
//                .apis(
//                        RequestHandlerSelectors.basePackage("com.XXX.controller.package2")
//                                .and(RequestHandlerSelectors.withClassAnnotation(Api.class))
//                                .and(RequestHandlerSelectors.withMethodAnnotation(ApiOperation.class))
//                )
//                .paths(PathSelectors.any())
//                .build()
//                .globalRequestParameters(buildParameters())
//                //赋予插件体系
//                .extensions(openApiExtensionResolver.buildExtensions(ApiConstant.GROUP_2));
//    }

    @Bean
    ApiInfo apiInfo() {
        //这里按照真实情况填写，会显示在接口目录页面
        return new ApiInfoBuilder()
                .title("Rest文档")
                .description("Rest文档")
                .termsOfServiceUrl("")
                .contact(new Contact(System.getProperty("spring.application.name"), "", "XXX@163.com"))
                .version("1.0")
                .build();
    }

    // 这里配置了一个公共header类型的参数‘Authorization’
    private List<RequestParameter> buildParameters(){
        RequestParameter parameter = new RequestParameterBuilder()
                .name("Authorization")
                .description("token令牌")
                .in(ParameterType.HEADER)
                .query(q -> q.model(m -> m.scalarModel(ScalarType.STRING)))
                .required(Boolean.FALSE)
                .build();

        List<RequestParameter> parameters = CollectionUtil.newArrayList();
        //TODO 临时屏蔽 parameters.add(parameter);
        return parameters;
    }
}
```

2. **WebMvcConfigurer**
   
   ```java
   @Configuration
   public class WebMvcConfig implements WebMvcConfigurer {
       /**
        * 静态资源映射
        */
       @Override
       public void addResourceHandlers(ResourceHandlerRegistry registry) {
           //swagger增强的静态资源映射
           registry.addResourceHandler("doc.html").addResourceLocations("classpath:/META-INF/resources/");
           registry.addResourceHandler("/webjars/**").addResourceLocations("classpath:/META-INF/resources/webjars/");
       }
   }
   ```
   
   ### 三、常用注解

#### 3.1 DTO层注解

```java
/**
 * 通用基础参数
 */
@ApiModel(value="BaseParam" , description = "通用基础参数")
@Data
public class BaseParam implements Serializable {
    private static final long serialVersionUID = 1L;

    /** 搜索值 */
    @ApiModelProperty(name = "searchValue", value = "搜索值")
    private String searchValue;

    /** 开始时间 */
    @ApiModelProperty(name = "searchBeginTime", value = "开始时间, 时间范围大于等于该时间", example = "2024-09-12")
    private String searchBeginTime;

    /** 结束时间 */
    @ApiModelProperty(name = "searchEndTime", value = "结束时间, 时间范围小于等于该时间", example = "2025-03-11")
    private String searchEndTime;

    /** 状态 */
    @ApiModelProperty(name = "searchStatus", value = "状态", allowableValues = "[0,2]")
    private Integer searchStatus;

}
```

#### 3.2 VO层

```java
--- VolumeVo.java
@Data
@AllArgsConstructor
@NoArgsConstructor
//value表示对象类的名称  description表示该对象类的描述
@ApiModel(value="VolumeVo" , description = "分析返回最终结果")
public class VolumeVo{
    //name 表示字段属性的名称   value表示字段属性的描述
    @ApiModelProperty(name = "source", value = "来源")
    private String source;

    @ApiModelProperty(name = "volumeTimeVoList", value = "统计结果列表")
    private List<VolumeTimeVo> volumeTimeVoList;
}

--- VolumeTimeVo.java
@Data
@ApiModel(value="VolumeTimeVo" , description = "统计结果")
public class VolumeTimeVo{
    //通过dataType属性显示声明属性类型 显示声明的内容优先级比自动探测的类型优先级高
    @ApiModelProperty(name = "key", value = "日期", dataType="string")
    private String key;

    @ApiModelProperty(name = "value", value = "统计数量")
    private Long value;

    // 通过hidden 把必要但不需要公开的属性隐藏起来 不在接口管理页面显示
    @ApiModelProperty(hidden=true, name = "ext", value = "附加信息")
    private String ext;
}
```

*一般情况下前后端真正交互的实体只有DTO、VO层，其它非交互的实体无需使用knife4j或swagger原生注解。*

#### 3.3 Controller层

```java
// 1. value 作为controller类的一个‘标签’，通常以按照业务划分即可
// 2. tags 也是coontroller类的标签，但允许把该类划分到多个‘标签’下，且优先级比value高
// 3. 这里的‘标签’比 ‘swagger Configuration’章节中提到的‘分组’层级要低一些，
//    属于在组内又进行了一次精确划分。
@Api(value = "领域", tags = "***业务")
@Validated
@RestController
public class XXXController {

    @Resource
	private DomainService domainService;

    /**
     * US分领域计算 <br/>
     * 注意： 该接口为暂时开放性接口，后续版本考虑删除
     */
    // Deprecated注解的效果也会作用域接口管理页面的显示效果，接口名称会显示为被中划线划掉
    @Deprecated
    // value 表示接口的名称 notes 表示对接口效果或其他有必要说明的内容信息。
    // produces 表示接口生产（返回）的数据格式，现代接口通常使用json数据格式即‘application/json’。
    @ApiOperation(
            value="US分领域计算",notes = "分领域计算说明：******",
            produces = MediaType.APPLICATION_JSON_VALUE)
    //ApiResponses 显式声明该接口的部分或全部响应状态及其含义以及不同响应状态下的返回的数据类型（通常不用写，由程序自动探测即可尤其是使用泛型的情况下）
    @ApiResponses({
            @ApiResponse(code = 200, message = "查询成功", reference = "ResponseData<Map<String,Object>>")
    })
    // ApiImplicitParams 对接口的部分或全部参数进行逐一说明
    @ApiImplicitParams(value = {
            // name 表示参数名(要和方法参数名一致) value 表示参数的描述
            // required 表示该参数是否为必填项 值为true表示必填 值为false表示可选
            // dataType|dataTypeClass 表示参数的数据类型 通常不用写由程序自动探测即可。
            // paramType 表示REST参数类型，可选值有：query、path、body、form、header。
            //           query参数表示由问号传参的形式传递的参数
            //           path参数表示由路径传参的形式传递的参数
            //           body参数表示POST、PUT请求传递的请求体内容
            //           form参数表示表单请求内容
            //           header参数表示请求头中的参数，如‘swagger configuration’章节中声明的‘Authoritarian’参数
            @ApiImplicitParam(name = "domainNameEnum", value = "领域名称", required=true, dataTypeClass = domainNameEnum.class, paramType = "path", example="us"),
            @ApiImplicitParam(name = "year", value = "年份", required=true, dataType = "int32",paramType = "path", example="2025"),
            @ApiImplicitParam(name = "calcConfigParam", value = "计算配置参数", required=true, dataTypeClass = CalcConfigParam.class, paramType = "body")
    })
    @PostMapping(value = {
                    "/calc/{domainName}/{fiscalYear}"})
    public ResponseData<Map<String,Object>> calcByDomain(
            @PathVariable @NotNull(message = "domainName 不能为空") DomainNameEnum domainName,
            @PathVariable @NotNull(message = "fiscalYear 不能为空") Integer year,
            @RequestBody @NotNull(message="计算配置参数不能为空") CalcConfigParam calcConfigParam
			) {
        
        return domainService.calcByDomain(domainName, year, calcConfigParam);
    }


    /**
     * US分领域计算第二版 <br/>
     * 注意： 该接口为暂时开放性接口，后续版本考虑删除
     */
    @Deprecated
    @ApiOperation(
            value="US分领域计算",notes = "分领域计算说明：******",
            produces = MediaType.APPLICATION_JSON_VALUE)
    @ApiResponse(code = 200, message = "计算成功")
    @ApiImplicitParams(value = {
            @ApiImplicitParam(name = "domainNameEnum", value = "领域名称", required=true, dataTypeClass = domainNameEnum.class, paramType = "path", example="us"),
            @ApiImplicitParam(name = "year", value = "年份", required=true, dataType = "int32",paramType = "path", example="2025"))
    })
    // ApiOperationSupport 对参数进行定制化展示
    //   includeParameters 配置‘calcConfigParam’对象中展示在接口页面中的属性
    //   ignoreParameters 配置‘calcConfigParam’对象中不展示在接口页面中的属性

    //    例如新增接口时,某实体类不需要显示Id,即可使用该属性对参数进行忽略.ignoreParameters={"id"}
    //    如果存在多个层次的参数过滤,则使用名称.属性的方式,例如 ignoreParameters={"uptModel.id","uptModel.uptPo.id"},其中uptModel是实体对象参数名称,id为其属性,uptPo为实体类,作为uptModel类的属性名称
    //    如果参数层级只是一级的情况下,并且参数是实体类的情况下,不需要设置参数名称,直接给定属性值名称即可.
	@ApiOperationSupport(
            ignoreParameters = {
                  "calcConfigParam.defaultConfigs"
            }
    )
    @PostMapping(value = {
                    "/calc/v2/{domainName}/{fiscalYear}"})
    public ResponseData<Map<String,Object>> calcByDomainV2(
            @PathVariable @NotNull(message = "domainName 不能为空") DomainNameEnum domainName,
            @PathVariable @NotNull(message = "fiscalYear 不能为空") Integer year,
            @RequestBody @NotNull(message="计算配置参数不能为空") CalcConfigParam calcConfigParam
			) {
         
        return domainService.calcByDomainV2(domainName, year, calcConfigParam);
    }

    // 表单上传接口 
    // 在演示环境下使用ApiImplicitParams对参数声明时无法达到预期效果（在接口页面测试接口时无法上传文件），
    // 多次测试下来使用下面的注解组合可以达到既可以在接口页面包含接口信息也可以正确的在接口页面测试接口。
  	@ApiOperation(value = "上传", notes = "文件(multipartFile)")
    @RequestMapping(value="/upload/{extension}/",
            method = RequestMethod.POST,
            consumes = MediaType.MULTIPART_FORM_DATA_VALUE,
            produces = MediaType.APPLICATION_JSON_VALUE)
    public ResponseData<FileInfoVo> upload(
            @ApiParam(name = "multipartFile", required = true) @RequestPart MultipartFile multipartFile,
            @ApiParam(name = "extension", required = true, allowableValues = "xlsx,zip") @PathVariable String extension,
            //@ApiParam 注解的hidden属性可以定制化的隐藏一些必要但暂时无需前端处理的参数
            @ApiParam(
                    required = false,
                    hidden = true,
                    name = "other",
                    value = "暂不支持使用，不传递该对象值即可。")
            @RequestParam(value = "other", required = false) Map other){

            ......
    }
}
```

### 四、声明

*实际开发中发现不同版本的knife4j、swagger在使用过程中，部分注解以及多注解组合的使用效果存在差异。*



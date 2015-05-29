
# ElasticBeanstalk shell scripts

This set of scripts allows you to control the process of AWS ElasticBeanstalk services, and make them reproduce-able. It has been tested successfully on Tomcat stacks.

The second purpose of this repository is also educational. It shows that one can control AWS API with shell scripts, using only [awscli](http://aws.amazon.com/cli/) and its bravest companion, [jq](http://stedolan.github.io/jq/).

# Yes, ElasticBeanstalk is complex

Despite having a running Elasticbeanstalk app running after some clicks on the AWS Console, its [documentation](http://docs.aws.amazon.com/elasticbeanstalk/latest/dg/Welcome.html) itself shows that it's complex. Automating ElasticBeanstalk deployment quickly becomes a PITA, especially the Auto Scaling configuration.

## ElasticBeanstalk components

* An **EB "Save Configuration"** explains how to deploy the ELB and EC2 instances
* An **EB "Application Version"** represents your code to be deployed
* An **EB "Environment"** is created using one "Save Configuration" and one "Application Version", and it will spawn new:
  * EC2 Elastic Load Balancer
  * EC2 Autoscaling Group
  * EC2 Security Groups
  * Some neat CloudWatch metrics
  * etc.
* Finally, the **EB Application** is just a container that holds:
  * Many **EB "Save Configurations"**
  * Many  **EB "Application Versions"**
  * Many **EB "Environments"**

## Use the AWS Console? Really?

Yes, you can use the AWS Console to create and manage your ElasticBeanstalk apps. But how would you do to document and reproduce your environements ? You can write a .docx file with something like:

1. On **us-west-1** region, open "My App" ElasticBeanstalk Application
2. Select the "My Env 2" Environment
3. Click on "Configuration"
4. Click on "Scaling"
5. Modify "Breach duration" to "5 minutes"
6. Click on "Apply"
7. ...

Or you can make your entire configuration text-driven, versionable and sharable with those scripts. Your call.

## Elasticbeanstalk inside a VPC

Before you use these scripts, have in mind that they've been written to host an application in a [Scenario 2 VPC setup](http://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/VPC_Scenario2.html). They should work in other scenarii. But they deffinitively wont work outside of a VPC.

# Pre-requisites

## Having awscli and jq installed

No kidding ?

```
pip install aws-cli
apt-get install jq
```

## Your application on an S3 bucket

Upload your application (.war, .zip) in an S3 bucket. You don't need to make it publicly accessible.

## AWS network components

According to the [Scenario 2 VPC setup](http://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/VPC_Scenario2.html), you should create:

* A VPC,
* Two subnets, one public, one private with the correct routing table(s),
* A Security Group to be applied to the EC2 instances.

The private subnet will host the EC2 instances. Those instances _will_ need to access to the Internet, so you will also need a [NAT instance](http://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/VPC_NAT_Instance.html) in the public subnet.

# The configuration files

# The ?conf file

Create one configuration file, using the example.conf file provided, for each ElasticBeanstalk deployment.

# The .json file

The .json file describes the "Saved Configuration" of your EB application. It is a template that will be filled by the `create_conf.sh` script. As you can have multiple "Saved Configuration" within a single application, you can create as many .json file as you want following the pattern `conf_template_WHATEVERYOUWANT.json`

# The scripts

The scripts in the `bin/` directory use a configuration file. See the `example.conf` file for all the variables that must be provided.

## create_app.sh

Creates an ElasticBeanstalk App. It's the easiest part, because it's an empty logical entity.

`./bin/create_app.sh path/to/your_config.conf`

## create_version.sh

Creates an application version. It represents the application you want to host.

`./bin/create_version.sh path/to/your_config.conf [app_file]`

If you specify the name of an `app_file`, it will override the `EB_APP_VERSION` variable from `your_config.conf`. Don't forget to replace its value in the conf file if its deployment is OK !
N.B: This script will not deploy your app. Use `deploy_version.sh` to specifically deploy an app in an existing environment.

## create_conf.sh

Creates a "Saved Configuration".

`./bin/create_conf.sh path/to/your_config.conf [template_name]`

If you specify the `template_name`, it will override the `EB_CONF_TEMPLATE` variable from `your_config.conf`.

The file `path/to/conf_template_[template_name].json` must contain the proper conf definition.

## create_env.sh

Creates an environment. Beware, once this script has run successfully, you will be billed by AWS for the EC2 resources it will automatically create.

`./bin/create_env.sh path/to/your_config.conf [environment|--] [configuration|--] [app_version]`

* If you specify the `environment` name, it will override the variable `EB_ENV` variable from `your_config.conf`. `--` makes the script use `EB_ENV`.
* If you specify the `configuration` name, it will override the variable `EB_CONF_TEMPLATE` variable from `your_config.conf`. `--` makes the script use `EB_CONF_TEMPLATE`.
* If you specify the `app_version`, it will override the variable `EB_APP_VERSION` variable from `your_config.conf`.

The script will automatically deploy your app on a newly created environment.

## create_beanstalk.sh

This script automates the run of the four scripts:

1. create_app.sh
2. create_version.sh
3. create_conf.sh
4. create_env.sh

`./bin/create_beanstalk.sh path/to/your_config.conf`

## deploy_version.sh

Deploys an application in an already created environment.

`./bin/deploy_version.sh path/to/your_config.conf [env_name|--] [app_version]`


* If you specify the `env_name`, it will override the variable `EB_ENV` variable from `your_config.conf`. `--` makes the script use `EB_ENV`.
* If you specify the `app_version`, it will override the variable `EB_APP_VERSION` variable from `your_config.conf`.

Don't forget that, if you deploy an app that is not what is in the `EB_APP_VERSION` variable, your configuration file will be out of sync from what's actually deployed. Don't forget to modify manually your configuration afterwards, the script won't do it for you.

## eb_status.sh

Prints usefull informations about your application's health:

* The env status
* It's Elastic Load Balancer instances status
* The 5 last Events of the environment

`./bin/eb_status.sh path/to/your_config.conf`

# License

The shell scripts inside the `bin/` directory are licensed under the GNU General Public License (GPL) v.3.

# Authors

* Grégoire Doumergue https://www.github.com/gdoumergue



# **Objetivo desse repositório**
Aprender sobre terraform, entender como se relaciona com a AWS e principais conceitos

# **Definições gerais do Terraform**
- Suporta configuração de nuvens públicas e privadas com base em uma linguagem de configuração de infraestrutura HCL (Hashicorp Configuration Language)
- Terraform possui um interpretador escrito em Go que interpreta a descrição do HCL, identifica status da infraestrutura atual, planeja e aplica um plano de adequação da infraestrutura atual para a infraestrutura declarada em HCL
- Permite criar ambientes "descartáveis" que podem ser replicados e testados antes de ser enviado para produção

### **Estrutura sintática**

- Principal elemento da linguagem são _Resources_, objetos de infraestrutura que declaram como a infraestrutura deveria ser
- Outros elementos servem apenas de suporte para flexibilização e reutilização de código
- A ordem dos blocos e elementos não afeta o resultado, pois a linguagem é declarativa

- Estrutura da linguagem segue o seguinte padrão:
```
<BLOCK TYPE> <BLOCK LABEL> <BLOCK LABEL/ALIAS> {
    # Block body
    <IDENTIFIER> = <EXPRESSION> #Argument
}
```
### **Estrutura de arquivos**
- Código armazenado em arquivos texto simples com extensão `.tf`, chamados de `configuration files`
- `Configuration files` usam SEMPRE enconding `UTF-8` e line ending do unix (LF)
- Conjunto de arquivos `.tf` ou `.tf.json` presentes na raiz de um **_mesmo diretório_** representam um módulo
- Arquivos de configuração presentes em sub-diretórios são interpretados como módulos distintos e não são diretamente incluídos nos arquivos de configuração da raiz
- Terraform segue **SEMPRE** uma estrutura de árvore, onde há apenas um `root module` e uma série de `child modules` derivados
- O `root module` é o diretório atual onde é chamado o `terraform init`

### **Module**

- Toda configuração do Terraform tem pelo menos 1 módulo, conhecido como `root module`
- Terraform interpreta todos os arquivos dentro de um mesmo módulo, tratando todos como um documento único
- Separação do código do módulo em arquivos distintos é por pura conveniência e _readability_
- Permitem reutilização de código de configuração de infraestrutura em diferentes casos de uso.
- Possuem variáveis de input e de output
- Um módulo pode chamar outro módulo (`child module`) através de **_Module Calls_**
- Mesmo `child module` pode ser chamado múltiplas vezes com diferentes configurações
- Chamadas podem ser de módulos presentes em sub-diretórios da raiz ou em módulos externos do **_Terraform Registry_**, conhecidos como `published modules`

#### **Module Blocks**
- Forma de chamar um `child module` dentro de um outro módulo passando valores específicos para as variáveis declaradas dentro do `child module`
- No exemplo abaixo, um módulo no subdiretório app-cluster é chamado e é atribuído um valor à variável de input `servers`
- O meta-argumento `source` precisa ser uma string literal, não pode ser uma expressão
 ```
 module "servers" {
  source = "./app-cluster"

  servers = 5
}
 ```

- Meta-argumentos: `source, version, count, for_each, providers, depends_on`
- O `source` pode ser especificado localmente ou em diversos serviços de hospedagem (Github, S3, Bitbucket, Terraform Registry, HTTP URLs, etc...)
- No `Local Path`, use e abuse de referências parciais como `./` e `../`

### **Terraform Registry**
- Uma espécie de repositório remoto de módulos, assim como um github, dockerhub ou flathub
- Para que um módulo seja publicado precisa atender a uma série de pré-requisitos
    - naming structure
    - repository description
    - standard module structure
    - supported version control system (like semantic versioning)
    - tags for release
- Registries podem ser privados ou públicos

### **Provider**
- Plugin oferecido por nuvens normalmente públicas
- Expande a linguagem e permite o uso de diversos módulos para provisionamento de infraestrutura em uma determinada nuvem pública (AWS, Google, Azure, etc)
- Implementa resources para gerenciar infraestruturas on-premise e cloud e os oferece como `resource types` para utilização em blocos de arquivos de configuração

#### **Required Providers**
Todo módulo terraform deve especificar no arquivo de configuração top-level os `providers` que depende, conforme exemplo abaixo

```
# main.tf
terraform {
    required_providers{
        custom_local_name = {
            source = 
            version = 
        }
    }
}

provider "custom_local_name" {

}
```

O bloco `required_providers` permite configuração de `local_name`,`source` e `version`, porém quase todo provider possui um "local name preferido". Os módulos da AWS normalmente começam com um prefixo `aws_` indicando que esse é o local name preferido para o provider

#### **Provider Configuration**
Após determinar quais são os providers necessários para a infraestrutura, o próximo passo é configurar o provider declarado. Esse passo também é feito no `root module`.

Cada provider determina quais são os argumentos necessários para a sua configuração. Mais a frente veremos da aws. 

#### **Dependency Lock File**
Para gerenciamento de dependências do projeto terraform como um todo, o terraform cria um arquivo `.terraform.lock.hcl` na pasta do `root module` para gerenciar dependências relacionadas a providers e módulos.
O arquivo é criado ao rodar `terraform init` e esse comando deve ser repetido a cada alteração no provider fornecido.

**Lembre de incluir esse arquivo no gerenciador de versões (git) do seu projeto**

### **Resource**
- Elemento mais importante da linguagem Terraform
- Cada `resource block` descreve um ou mais objetos de infraestrutura


#### **Resource Block**

Sintaxe de declaração simples do resource block segue conforme abaixo
```
resource "<<type>>" "<<local_name>>"{
    # argument 1
    # argument 2
}
```
Cada `argument` dentro de um `resource block` é dependente do `resource type`, sendo que há normalmente uma combinação de `required arguments` e `optional arguments`. Os valores de um `argument` podem ser fixos ou dinâmicos.

Por padrão, o terraform identifica automaticamente o `provider` a partir do `resource_type`, mas caso estejam sendo usadas múltiplas configurações de um mesmo provider, será necessário identificá-lo utilizando o meta-argument `provider`.

#### **Resource Behavior**

Um resource só será representado fisicamente na infraestrutura real quando for aplicado o comando `terraform apply`. Nesse momento, os novos resources declarados são criados e o identificador do objeto real é armazenado no `terraform state`, sendo modificado ou destruídos a partir de novas mudanças.

#### **Accessing Resource Attributes**

Dentro de um mesmo módulo, é possível referenciar atributos de um outro `resource block` usando a sintaxe de expressões `<RESOURCE_TYPE>.<LABEL>.<ATTRIBUTE>`. Essa regra também vale para atributos `read only`, como por exemplo IDs aleatórios que são gerados durante a criação da infraestrutura pela API do provider.

O uso de expressões para referenciamento entre resources de um mesmo módulo é extremamente importante para o interpretador gerar a árvore de dependências de criação dos resources.

#### **Resource Dependencies**

Normalmente tratado automaticamente pelo intepretador usando informações disponíveis pelas interconexões de expressions. Para dependências "escondidas", é possível utilizar o meta-argumento `depends_on`

#### **Meta-arguments**
Argumentos que aparecem independentemente do `resource_type`
- **depends_on**: for specifying hidden dependencies
    - Especialmente importante para evitar erros bestas, ver [https://www.terraform.io/docs/language/meta-arguments/depends_on.html](https://www.terraform.io/docs/language/meta-arguments/depends_on.html)
- **count**: for creating multiple resource instances according to a count
- **for_each**: to create multiple instances according to a map, or set of strings
    - Especialmente útil para reutilização, ver [https://www.terraform.io/docs/language/meta-arguments/for_each.html](https://www.terraform.io/docs/language/meta-arguments/for_each.html)
- **provider**: for selecting a non-default provider configuration lifecycle, for lifecycle customizations
- **provisioner and connection**: for taking extra actions after resource creation

### **Data Source**
- Tipo específico de resource usado exclusivamente para procurar informações
- Muitos data sources são remotos acionados por alguma API do provider, porém é possível criar data sources locais para ler arquivos, renderizar templates, ou IAM policies

Exemplo:
```
# Find the latest available AMI that is tagged with Component = web
data "aws_ami" "web" {
  filter {
    name   = "state"
    values = ["available"]
  }

  filter {
    name   = "tag:Component"
    values = ["web"]
  }

  most_recent = true
}
```

### **Variables**
- Parâmetros de configuração de `modules` sem alterar o source code
- Variáveis declaradas no `root module` podem ter seu valor `set` na chamada do `terraform CLI` ou por meio de `environment variables`
    - Exemplo clássico dessa propriedade pode ser observado na autenticação do terraform no provider AWS
- Variáveis delcaradas em `child modules` tem seu valor especificado no `module block`

#### **Variable Declaration**
A declaração de variáveis em um módulo ocorre a partir de um bloco `variable` com um identificador de nome de variável. Cada nome de variável deverá ser único dentro de um mesmo módulo. Exemplo abaixo:

```
variable "env" {
    type = string
    default = "dev"
    sensitive = false
    description = "Environment variable relating to infrastructure code. Can be prod, dev or stg"
    validation {
        condition = contains(["prod","stg","dev"], var.env)
        error_message = "env = ${var.env} is not a valid input. env must be one of the following: prod, stg, dev"
    }
}
```

#### **Variable Block Arguments**
Há 5 possíveis argumentos dentro do bloco variable:
- **type**: Composição de um construtor [list(<TYPE>), set(<TYPE>), map(<TYPE>), tuple([<TYPE>,...]), object({<ATTR NAME> = <TYPE>, ...})] e de um tipo [string, number, bool] 
- **default**: Valor padrão atribuído a variável caso não seja especificada. Ter o atributo default torna a variável opcional
- **sensitive**: Quando setada como `true` limita o output dos comandos `terraform plan` e `terraform apply`
- **description**: Descrição usada para documentação
- **validation**: Bloco de regras adicionais ao type para validação do valor definido nas variáveis. Possui argumentos `condition <bool>` e `error_message <string>`

#### **Assigning values to root module variables**
Há 4 formas possíveis de atribuir valores para variáveis do root module

**1. Terraform Cloud workspace**

**2. Parâmetro `-var` no terraform CLI**
    ```
    terraform apply -var="image_id=ami-abc123"
    terraform apply -var='image_id_list=["ami-abc123","ami-def456"]' -var="instance_type=t2.micro"
    terraform apply -var='image_id_map={"us-east-1":"ami-abc123","us-east-2":"ami-def456"}'
    ```

**3. Arquivos de definição de variáveis `.tfvars` ou `.tfvars.json`**

    Um arquivo específico pode ser especificado pelo terraform CLI
    ```
    terraform apply -var-file="testing.tfvars"
    ```

    Caso as variáveis não sejam especificadas, o terraform, por padrão, procurará na raiz do repositório:  
        - arquivos nomeados exatamente como `terraform.tfvars` ou `terraform.tfvars.json`
        - arquivos com os sufixos `.auto.tfvars` ou `.auto.tfvars.json`
    
    Exemplo de formatação dos arquivos:
    ```
    $ cat terraform.tfvars
    image_id = "ami-abc123"
    availability_zone_names = [
    "us-east-1a",
    "us-west-1c",
    ]

    $ cat terraform.tfvars.json
    {
        "image_id": "ami-abc123",
        "availability_zone_names": ["us-west-1a", "us-west-1c"]
    }
    ```
**4. Variáveis de ambiente**

    Para que o terraform reconheça configurações de variáveis como variáveis de ambientes, será necessário definí-las com o prefixo `TF_VAR_`
    ```
    $ export TF_VAR_image_id=ami-abc123
    $ terraform plan
    ...
    ```

Ordem de carregamento de variáveis, as últimas possuem prioridade com relação às primeiras:
1. Environment variables
2. The terraform.tfvars file, if present.
3. The terraform.tfvars.json file, if present.
4. Any *.auto.tfvars or *.auto.tfvars.json files, processed in lexical order of their filenames.
5. Any -var and -var-file options on the command line, in the order they are provided. (This includes variables set by a Terraform Cloud workspace.)

#### **Assigning values to child module variables**

### **Local Values**
- Muito parecidas com variáveis, porém estão contidas somente dentro do módulo ao qual são definidas, como uma espécie de variáveis temporárias definidas dentro do escopo de uma função
- Não possuem acesso de input / output externo
- Útil quando um mesmo valor é usado múltiplas vezes dentro do módulo e pode ser alterado no futuro
- Suportarm a definição de um nome único e atribuição de uma expressão a ela, conforme exemplo abaixo

```
locals {
  service_name = "forum"
  owner        = "Community Team"
}

locals {
  # Common tags to be assigned to all resources
  common_tags = {
    Service = local.service_name
    Owner   = local.owner
  }
}

resource "aws_instance" "example" {
  # ...

  tags = local.common_tags
}
```

### **Outputs Values**
- Funciona como o `return`de uma função
- Um `child module` pode usar output values para expor variáveis para o uso pelo `parent module`
- Um `root module` pode usar output values como mensagens de retorno ao CLI depois de rodar `terraform apply`

Cada output individual recebe um bloco `output` com um argumento `value` obrigatório e argumentos opcionais `description`,`sensitive`,`depends_on`
```
output "instance_ip_addr" {
    value = aws_instance.server.private_ip
    description = "The private IP address of the main server instance."
}

output "db_password" {
  value       = aws_db_instance.db.password
  description = "The password for logging in to the database."
  sensitive   = true
}
```

Para acessar os valores exportados de `child modules`no `parent module`, basta usar a expressão `module.<MODULE NAME>.<OUTPUT NAME>`. O exemplo abaixo mostra como acessar:
```
# main.tf

module "foo" {
  source = "./mod"
}

resource "test_instance" "x" {
  some_attribute = module.mod.a # resource attribute references a sensitive output
}

output "out" {
  value     = "xyz"
  sensitive = true
}

# mod/main.tf, our module containing a sensitive output

output "a" {
  value     = "secret"
  sensitive = true
}
```

## **Bloco Terraform**
- Usado para configurações gerais do terraform
- Especifica o backend, required_providers e uma versão específica do terraform para uso
- `backend` é um argumento do tipo bloco que especifica onde as operações do terraform serão processadas
- `required_providers` é usado para especificar o provider da cloud
- `required_versions` é um argumento string que especifica a versão do terraform para rodar os arquivos de configuração

```
# main.tf
terraform {
  required_providers {
    aws = {
      version = ">= 2.7.0"
      source = "hashicorp/aws"
    }
  }
}
```

## **Terraform Backend**
- Onde as operações são processadas e os `states` snapshots são salvos
- Remote backend é uma ferramenta muito útil para não compartilhar informações sensíveis em repositórios públicos e privados por meio do arquivo de `states` do terraform
- Remote backend evita também que versões diferentes do arquivo states rodem na máquina de diferentes pessoas  

## **Terraform States**


# **Configurações gerais para usar AWS com Terraform**

Para usar o terraform com a AWS, normalmente há uma série de configurações que precisam ser realizadas.
Os códigos de configuração ficam, por convenção, num arquivo `main.tf` na raiz do repositório.

## **Configurações gerais do bloco Terraform**
Primeiro configuramos a versão e origem do provider para garantir que teremos um código terraform funcionando sempre.

```
terraform {
  required_providers {
      aws = {
          source = "hashicorp/aws"
          version = "~> 3.0"
      }
  }
```
No argumentos `source` a indicação `hashicorp/` é uma referência ao repositório web oficial da Hashicorp [https://registry.terraform.io/providers/hashicorp/](https://registry.terraform.io/providers/hashicorp/)

No argumentos `version` é possível especificar travas para a versão do código do provider. Cada provider disponibiliza o código num formato de [Versionamento Semântico](https://semver.org/lang/pt-BR/).
Operador `~>` permite aceitar qualquer versão mais atual nos doi níveis inferiores do versionamento semântico `3.X.Y`, onde nãp há mudanças com quebra de compatibilidade

Para mais informações, acessar [o link](https://learn.hashicorp.com/tutorials/terraform/provider-versioning?in=terraform/cli)

## **Configurações gerais do bloco provider da AWS**

O bloco de provider da AWS é um plugin que permite  informações gerais que são reutilizadas por todo o repositório de infraestrutura do terraform. Esse bloco é responsável pela configuração de credenciais de aceso ao ambiente da AWS, região, account_id e outras configurações gerais. Sua definição mínima não necessita nenhum argumentos, carregando diversos valores por default das variáveis de ambiente do sistema.

```
provider "aws" {}
```

### **Valores de argumentos**

Argumentos do provider AWS são opcionais porque o terraform procura informações em diversos locais da máquina de desenvolvimento local. A ordem de busca segue na seguinte ordem:

1. Valores de argumentos _hardcoded_ no arquivo `main.tf`
2. Valores presentes em variáveis de ambiente
3. Valores presentes em arquivos de credenciais compartilhado

### **1. Argumentos _hardcoded_ no arquivo `main.tf`**

Não recomendado para os argumentos `access_key`, `secret_key`e `token` por motivos de segurança (especialmente em repositórios compartilhados), mas pode ser útil para argumentos menos críticos como `region` ou `http_proxy`.

O bloco de configuração do provider ficaria dessa forma
```
provider "aws" {
    region = "us-east-2"
    access_key = "AKXZ**********"
    secret_key = "*****************"
}
```

### **2. Valores presentes em variáveis de ambiente**
Por padrão, o terraform tentará obter valores para os argumentos `region`,`access_key`, `secret_key` a partir das variáveis de ambiente do sistema caso não seja especificado de maneira hardcoded. Abaixo o mapeamento de variáveis de ambiente para argumentos do do bloco provider da AWS.

| Variável de Ambiente      | Argumento provide AWS     |
| ------------------------- | ------------------------- |
| `AWS_ACCESS_KEY_ID`       | `access_key`              |
| `AWS_SECRET_ACCESS_KEY`   | `secret_key`              |
| `AWS_DEFAULT_REGION`      | `region`                  |
| `AWS_SESSION_TOKEN`       | `token`                   |

Em configurações comuns, as credenciais de acesso `AWS_ACCESS_KEY_ID` e `AWS_SECRET_ACCESS_KEY` são combinadas com definições _hardcoded_, como abaixo:

**Linux**
```
$ export AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
   # The access key for your AWS account.
$ export AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
   # The secret access key for your AWS account.
```
**Windows**
```
C:\> SET  AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
   # The access key for your AWS account.
C:\> SET  AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
   # The secret access key for your AWS account.
```

**Terraform**
```
provider "aws" {
    region = "us-east-2"
}
```

### **3. Valores presentes em arquivo de credenciais compartilhado**

Caso não sejam identificados argumentos no código terraform do bloco do provider e variáveis de ambiente não estejam disponíveis, o terraform buscará os dados no arquivos de credenciais do AWS CLI na máquina local. 
É importante destacar que essa opção só se mostra disponível para os argumentos `access_key` e `secret_key`.

```
$ cat ~/.aws/credentials
[default]
aws_access_key_id = **************
aws_secret_access_key = ********************

[prod]
aws_access_key_id = **************
aws_secret_access_key = ********************
```

A partir do argumento `profile` é possível escolher entre as credenciais definidas como `default` ou como `any-profile-name`

```
provider "aws" {
    alias
    region = "us-east-2"
    profile = "default"
}
```

O argumento `shared_credentials_file` permite ainda indicar um arquivo de configurações diferente do padrão presente em `~/.aws/credentials`, conforme exemplo abaixo referenciando um arquivo de credenciais em um subdiretório da raiz do repositório:

```
provider "aws" {
    region = "us-east-2"
    profile = "prod"
    shared_credentials_file = "./creds_folder/creds"
}
```

### **Meta-argumento `alias`**

Todo provider da aws possui um meta-argumento `alias` que pode ser usado para instanciar diversas versões de um mesmo provider com diferentes configurações para diferentes resources, como no exemplo abaixo

```
providers "aws" {
    alias = "east"
    region = "us-east-2"
    profile = "prod"
}

providers "aws" {
    alias = "west"
    region = "us-west-2"
    profile = "prod"
}

resource "aws_s3_bucket" "west-bucket" {
    provider = aws.west
    ...
}

resource "aws_s3_bucket" "east-bucket" {
    provider = aws.east
    ...
}
```
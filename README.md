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


### **Outputs**

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
}
```
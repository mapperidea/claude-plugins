# CLI Mapper Idea

*Referência da skill `mapperidea` — carregada sob demanda. Volte ao `SKILL.md` para o roteiro.*

## CLI Mapper Idea (referência rápida)

O CLI tem dois nomes equivalentes: `mapperidea` (completo) e `mi` (abreviado). Os subcomandos também têm abreviações.

### 1. Inicializar projeto — `init`

Executar **dentro da pasta onde estão os mapas**. Vincula um nome de projeto ao diretório:

```bash
cd /caminho/para/meu/projeto/mapas
mapperidea init nome-do-projeto mapa.mm
```

Após o `init`, todos os outros comandos podem ser executados de qualquer diretório usando o nome do projeto.

### 2. Push — `push` / `p`

Sobe **todos os mapas do projeto** para o engine (não um arquivo individual):

```bash
mi p nome-do-projeto
# equivalente a:
mapperidea push nome-do-projeto
```

O `push` **não valida** o conteúdo: ele só envia. É obrigatório a cada alteração de qualquer `.mi` porque
todos os outros comandos rodam **no servidor**, sobre a última versão enviada — sem `push`, você valida e
gera o mapa de antes.

### 3. Validar — `check` / `load` / `compile`

A validação acontece quando o servidor **lê** o mapa. Os comandos formam uma escada: cada um refaz os
anteriores e acrescenta um passo, então subir degrau a degrau mostra **onde** está o erro.

```bash
mi k nome-do-projeto                          # check:   o que foi enviado chegou inteiro e está acessível
mi l nome-do-projeto                          # load:    o mapa principal e os ligados são lidos e viram o DOM
mi c nome-do-projeto nome-gerador sub-gerador # compile: o gerador compila contra o mapa, sem gerar nada
```

Erro vem como `EMI…` seguido do texto do problema; no `compile`, com o trecho do gerador onde falhou.

**`load` e `compile` passarem não prova que o mapa está certo** — prova que é legível e que o gerador
compila. Um link para um mapa que não existe não falha o `load` (vira nó vazio), e uma propriedade `@` fora
do vocabulário é descartada sem aviso. Quem mostra isso é o `struct`:

```bash
mi g nome-do-projeto struct xml className=Pedido packageName=com.exemplo.dominio > /tmp/pedido.xml
```

O `struct` vem no pack padrão — existe em todo projeto — e despeja a forma normalizada da classe. Rodá-lo
completo é a validação de referência do mapa.

### 4. Gerar código — `generate` / `g`

```bash
mi g nome-do-projeto nome-gerador sub-gerador param1=valor1 param2=valor2 > arquivo-saida
```

Exemplo real com variáveis de ambiente e redirecionamento de saída:

```bash
mi g teste quarkus domain modelName=$MODEL_NAME package=$PACKAGE > "$BASE_PATH/domain/${MODEL_NAME}.java"
```

Erro de execução do gerador volta **dentro da saída**, não como falha do comando: redirecionado com `>`,
o `EMI…` fica escrito no arquivo gerado. Depois de gerar, confira com `grep -rl 'EMI[0-9]' <destino>`.

### Script de geração múltipla — padrão recomendado

Quando um stack de arquitetura exige vários geradores por classe (ex: Quarkus gera entity, domain, mapper, repository, builder e resource), o padrão recomendado é um script bash com seletor por tipo:

```bash
#!/bin/bash

# Verifica se o nome do modelo foi passado
if [ -z "$1" ]; then
    echo "Erro: Você precisa passar o nome do modelo."
    echo "Uso: $0 NomeDoModelo [all|entity|domain|mapper|repository|builder|resource]"
    exit 1
fi

MODEL_NAME=$1
# Pega o segundo parâmetro ou define 'all' como padrão
TYPE_TO_GENERATE=${2:-all}
# Normaliza para minúsculas (evita erros de digitação como Entity -> entity)
TYPE_TO_GENERATE=$(echo "$TYPE_TO_GENERATE" | tr '[:upper:]' '[:lower:]')

PROJECT="acme-pedidos"
PACKAGE="br.com.acme.domain.pedidos"
BASE_PATH="../quarkus/src/main/java/br/com/acme/pedidos"

echo "================================================="
echo "⚙️  Iniciando geração para: $MODEL_NAME"
echo "📂 Tipo solicitado: $TYPE_TO_GENERATE"
echo "================================================="

gen_entity() {
    echo "Gerando Entity..."
    mi g $PROJECT quarkus entity modelName=$MODEL_NAME package=$PACKAGE > "$BASE_PATH/entity/${MODEL_NAME}Entity.java"
}

gen_domain() {
    echo "Gerando Domain..."
    mi g $PROJECT quarkus domain modelName=$MODEL_NAME package=$PACKAGE > "$BASE_PATH/domain/${MODEL_NAME}.java"
}

gen_mapper() {
    echo "Gerando Mapper..."
    mi g $PROJECT quarkus mapper modelName=$MODEL_NAME package=$PACKAGE > "$BASE_PATH/mapper/${MODEL_NAME}Mapper.java"
}

gen_repository() {
    echo "Gerando Repository..."
    mi g $PROJECT quarkus repository modelName=$MODEL_NAME package=$PACKAGE > "$BASE_PATH/repository/${MODEL_NAME}Repository.java"
}

gen_builder() {
    echo "Gerando Builder..."
    mi g $PROJECT quarkus builder modelName=$MODEL_NAME package=$PACKAGE > "$BASE_PATH/builder/${MODEL_NAME}EntityBuilder.java"
}

gen_resource() {
    echo "Gerando Resource..."
    mi g $PROJECT quarkus resource modelName=$MODEL_NAME package=$PACKAGE > "$BASE_PATH/resource/${MODEL_NAME}Resource.java"
}

case "$TYPE_TO_GENERATE" in
    all)
        gen_entity; gen_domain; gen_mapper
        gen_repository; gen_builder; gen_resource
        ;;
    entity)     gen_entity ;;
    domain)     gen_domain ;;
    mapper)     gen_mapper ;;
    repository) gen_repository ;;
    builder)    gen_builder ;;
    resource)   gen_resource ;;
    *)
        echo "❌ Erro: Tipo '$TYPE_TO_GENERATE' não reconhecido."
        echo "Opções válidas: all, entity, domain, mapper, repository, builder, resource"
        exit 1
        ;;
esac

echo "✅ Arquivos gerados com sucesso em $BASE_PATH"
```

**Uso:**
```bash
./generate.sh Pessoa          # gera todos os tipos para Pessoa
./generate.sh Pessoa entity   # gera apenas a Entity
./generate.sh Pedido mapper   # gera apenas o Mapper de Pedido
```

Quando solicitado a criar um script de geração, use este modelo como base, adaptando `PROJECT`, `PACKAGE`, `BASE_PATH` e os geradores disponíveis no projeto.

### Resumo de comandos

| Completo | Abreviado | Descrição |
|----------|-----------|-----------|
| `mapperidea init <projeto> <mapa.mm>` | — | Inicializa projeto na pasta atual |
| `mapperidea push <projeto>` | `mi p <projeto>` | Sobe todos os mapas do projeto — não valida |
| `mapperidea check <projeto>` | `mi k <projeto>` | Confere que o envio chegou inteiro e acessível |
| `mapperidea load <projeto>` | `mi l <projeto>` | Lê os mapas e monta o DOM — o mapa é legível? |
| `mapperidea compile <projeto> <gerador> <sub>` | `mi c <projeto> <gerador> <sub>` | Compila o gerador sem gerar |
| `mapperidea generate <projeto> <gerador> <sub> [params]` | `mi g <projeto> <gerador> <sub> [params]` | Executa gerador com parâmetros; com `struct xml`, valida a forma da classe |

---

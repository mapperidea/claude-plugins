# Mapper Idea — plugins para Claude Code

Dois plugins do [Claude Code](https://claude.com/claude-code), distribuídos por este marketplace:

| Plugin | Para que serve | Precisa de |
|---|---|---|
| **`agent-kit`** | criar agentes Claude Code bons: um wizard que entrevista você, busca conhecimento de domínio e escreve o agente no seu projeto | só o Claude Code |
| **`iadd`** | *IA Driven Development* com Mapper Idea: da história ao mapa de negócio, do mapa de arquitetura ao código gerado, com uma tríade de agentes que conduz cada etapa | o CLI `mi` com usuário autorizado ([licença](#licença)) |

Os dois são independentes para instalar. O `iadd` usa os hooks de segurança do `agent-kit`, então quem
usa `iadd` instala os dois.

---

## 1. Instalação

Dentro do Claude Code:

```
/plugin marketplace add mapperidea/claude-plugins
/plugin install agent-kit@mapperidea-iadd
/plugin install iadd@mapperidea-iadd
```

Ou pelo terminal:

```sh
claude plugin marketplace add mapperidea/claude-plugins
claude plugin install agent-kit@mapperidea-iadd
claude plugin install iadd@mapperidea-iadd
```

> **Abra uma sessão nova depois de instalar.** Uma sessão que já estava aberta não enxerga as skills de
> um plugin instalado no meio dela: o comando falha com `Unknown skill`. Não é defeito do plugin.

Para conferir: `/plugin` lista o que está instalado, e digitar `/agent-kit:` ou `/iadd:` mostra os
comandos disponíveis.

### Atualizar

```
/plugin marketplace update mapperidea-iadd
```

Atualizar o plugin **não** mexe no que ele já escreveu no seu projeto — veja [§4](#4-o-que-fica-no-seu-projeto).

### Desinstalar

```
/plugin uninstall iadd@mapperidea-iadd
/plugin uninstall agent-kit@mapperidea-iadd
```

---

## 2. `agent-kit` — criando um agente

### O wizard

```
/agent-kit:agent-creator
/agent-kit:agent-creator "revisor de SQL para PostgreSQL"
/agent-kit:agent-creator --scope user "tradutor técnico"
/agent-kit:agent-creator --enrich revisor-sql
```

| Forma | O que faz |
|---|---|
| sem argumento | entrevista completa, desde o propósito |
| `"descrição"` | começa já com a ideia do agente |
| `--scope project` (padrão) | grava em `.claude/agents/` do projeto — o agente vai junto com o repositório |
| `--scope user` | grava em `~/.claude/agents/` — o agente vale em todos os seus projetos |
| `--enrich <agente>` | acrescenta conhecimento de domínio a um agente que já existe |

Você também pode só pedir em linguagem natural ("cria um agente que revisa migrations") — o Claude
aciona o wizard sozinho.

### O que o wizard pergunta

1. **Descoberta** — o que o agente faz, para quem, o que ele *não* deve fazer. Se já existe um agente
   pronto parecido, ele oferece partir dele (há 11 prontos e 4 arquétipos).
2. **Conhecimento** — procura uma fonte autoritativa do domínio: um arquivo seu (PDF, `.md`, runbook), a
   documentação oficial, uma URL. Você pode apontar a fonte.
3. **Arquitetura** — que ferramentas o agente pode usar, qual modelo, que permissões.
4. **Comportamento** — como ele trabalha, quando para e pergunta, como relata.
5. **Configuração** — memória, hooks de segurança.
6. **Geração** — escreve o arquivo e mostra o resultado.

### Quando não há fonte de conhecimento

Se o wizard não acha fonte externa (sem arquivo seu, com o site oficial bloqueando a busca), ele
**entrevista você** e marca o resultado como *Tier D*. É um resultado legítimo: é o conhecimento do seu
time, e por isso vai para a memória do agente (`.claude/agent-memory/<agente>/MEMORY.md`), porque não
existe em outro lugar. Só quando não houve fonte alguma o agente fica marcado *Tier E*, declarado no
cabeçalho dele — nunca em silêncio.

### Hooks de segurança

Alguns agentes declaram um hook que bloqueia escrita fora das pastas permitidas ou comandos de shell
perigosos. O hook aponta para `scripts/` **do seu projeto**, então os scripts precisam ser copiados para lá
uma vez. O wizard oferece isso quando o agente tem hook; à mão:

```sh
~/.claude/plugins/cache/mapperidea-iadd/agent-kit/<versão>/scripts/install-into-project.sh /caminho/do/projeto
```

(use a maior `<versão>` que houver na pasta). Um agente com hook apontando para script inexistente falha
em toda escrita — se não quiser o hook, remova o bloco `hooks:` do agente.

---

## 3. `iadd` — desenvolvendo com Mapper Idea

### Pré-requisito

O CLI `mi` instalado e autenticado com um usuário autorizado. Sem ele, a tríade não tem como validar nem
gerar nada.

### Primeiro passo: `/iadd:init`

Na raiz do seu projeto:

```
/iadd:init
```

Ele procura o que você já tem e conduz a partir daí:

- **mapas FreeMind (`.mm`)** existentes → converte para `.mi`, em lote, com um relatório dos ícones que
  não tinham equivalente;
- identifica o **mapa principal**;
- instala a **tríade de agentes** em `.claude/agents/`, entrevistando você para preencher o que é do seu
  domínio, e traz os guias e os hooks junto.

Para (re)instalar um agente só: `/iadd:init domain-mapper`, `/iadd:init generator-author`,
`/iadd:init cli-runner`, ou `/iadd:init todos`.

### A tríade

| Agente | É dono de | Toca em |
|---|---|---|
| **`domain-mapper`** | o Mapa de Negócio — entidades, atributos, relações, regras | só arquivos `.mi` de negócio |
| **`generator-author`** | os geradores — como o mapa vira código na sua stack | só arquivos `.mi` de gerador |
| **`cli-runner`** | a validação e a geração de verdade, pelo CLI `mi` | roda `mi`, não edita mapa |

Você conversa com o Claude normalmente ("adiciona a entidade Fornecedor com CNPJ e razão social") e ele
delega ao agente certo. A separação existe para que quem modela não gere, e quem gera não mude o modelo.

### O ciclo

```sh
cd mi/ && mi init <projeto> main.mi      # uma vez: vincula o projeto à pasta do mapa principal
mi push <projeto>                        # a cada alteração de qualquer .mi — envia, não valida
mi generate <projeto> <grupo> <sub> modelName=<Classe> package=<pacote> > <destino>
```

O `push` só leva os mapas para a nuvem; é lá que tudo acontece, então ele vem antes de qualquer outro
comando. **Quem valida é a geração**, e o CLI tem uma escada para achar onde está o erro:

| Comando | O que confirma |
|---|---|
| `mi check <projeto>` | o envio chegou inteiro |
| `mi load <projeto>` | o mapa é legível e vira a estrutura que os geradores leem |
| `mi compile <projeto> <grupo> <sub>` | o gerador compila, sem gerar nada |
| `mi generate <projeto> struct xml className=<C> packageName=<p>` | a classe tem a forma que você pretendia — **a validação do mapa** |

Legível não é certo: um link para mapa inexistente ou uma propriedade desconhecida passam pelo `load` em
silêncio, e só o `struct` mostra. Os agentes sabem disso e não declaram um mapa válido sem ter rodado o
`struct` na classe.

### Referência de sintaxe `.mi`

```
/iadd:mi          # atalho
/iadd:mapperidea  # nome completo
```

Lê, escreve, valida e explica mapas `.mi` — de negócio, de arquitetura, geradores, ícones, tipos.

### Packs de geradores

O plugin traz packs de partida, cada um com um README de contrato (o que ele assume do seu mapa):

| Pack | Para quê |
|---|---|
| `_exemplar` | didático — o menor gerador completo, para aprender a escrever o seu |
| `quarkus` | backend Java/Quarkus, com exemplo executável |
| `frontend` | frontend — em evolução |

### Para ler

Dentro do plugin (`~/.claude/plugins/cache/mapperidea-iadd/iadd/<versão>/`), ou peça ao Claude que abra:

- `docs/pipeline-iadd.md` — o método inteiro: as etapas, quem é dono de cada uma, onde a validação
  acontece. **Comece por aqui.**
- `references/generator-authoring-guide.md` — como se escreve um gerador do zero, lido junto com
  `packs/_exemplar/`.

---

## 4. O que fica no seu projeto

Estes plugins são **semente, não framework**. O que eles escrevem no seu projeto — agentes, memória,
guias, hooks, geradores, mapas — passa a ser **seu**:

- **Continua funcionando sem o plugin.** Nada do que é gerado aponta para dentro do plugin. Pode
  desinstalar.
- **É para ser editado.** Cada agente e guia tem uma seção *"O que você provavelmente vai querer mudar
  aqui"*, que separa o método (o que vale em qualquer projeto) das premissas (o que foi um palpite sobre o
  seu).
- **Atualizar o plugin não sobrescreve nada.** Se uma versão nova trouxer algo que você quer, compare e
  traga à mão — ou rode `/iadd:init <agente>` de novo, que pergunta antes de substituir.

| Onde | O quê |
|---|---|
| `.claude/agents/` | os agentes |
| `.claude/agent-memory/<agente>/` | o que cada agente aprendeu sobre o seu projeto |
| `scripts/` | os scripts dos hooks de segurança |

Vale commitar tudo isso: é assim que o time inteiro passa a usar os mesmos agentes.

---

## 5. Problemas comuns

| Sintoma | Causa e saída |
|---|---|
| `Unknown skill` logo depois de instalar | a sessão já estava aberta — abra uma nova |
| agente falha em **toda** escrita | hook declarado, script ausente — rode o `install-into-project.sh` ([§2](#hooks-de-segurança)) |
| `mi generate` devolve arquivo vazio, sem erro | rode `mi compile` no gerador para descartar erro de compilação; se passar, o gerador não casou com nada: nome de classe, pacote ou sub-gerador errado, ou caminho `#` fora da pasta onde se rodou `mi init`. Veja o checklist em `docs/pipeline-iadd.md` |
| arquivo gerado contém `EMI…` | é erro do `mi`, saído no stdout e redirecionado para dentro do arquivo. Depois de gerar, confira com `grep -rl 'EMI[0-9]' <destino>` |
| `mi` recusa autenticação | o usuário não está autorizado — veja [Licença](#licença) |

---

## Licença

O uso deste material é **atrelado ao licenciamento de acesso ao Mapper Idea**. Na prática também é
dependência técnica: o `iadd` opera o CLI `mi`, que exige usuário autorizado.

Para pedir uma licença: **contato@mapperidea.io**. Detalhes em [`LICENSE`](LICENSE).

**O que você produz com os plugins é seu** — agentes, mapas, geradores e código gerado.

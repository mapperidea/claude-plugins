# Pipeline IADD — desenvolvimento dirigido por IA com Mapper Idea

**Status**: v0.1 — primeira escrita do método (fase B0 do plano de generalização)
**Data**: 2026-09-17
**Público**: quem vai adotar IADD num projeto novo, e quem vai escrever os arquétipos de agente que operam o método.

Este documento é o **método escrito**. Até aqui ele existia distribuído entre o plano de implementação de um
projeto, os prompts de três agentes e a cabeça de quem o inventou. Todos os outros artefatos do kit — arquétipos,
packs de geradores, guias — são peças que só fazem sentido com este manual de montagem ao lado.

---

## 0. O que é IADD — e o que não é

**IADD (IA Driven Development)** é o uso de IA em desenvolvimento com um **artefato intermediário versionado**
entre a intenção e o código: o **mapa**. A IA não escreve a aplicação linha a linha. Ela faz duas coisas
diferentes disso:

1. **modela o negócio** num Mapa de Negócio `.mi`, e
2. **escreve o gerador** (Mapa de Arquitetura) que transforma esse mapa em código.

O código de aplicação é **saída determinística** de um gerador — não é texto produzido por amostragem. Duas
execuções sobre o mesmo mapa produzem o mesmo código. É isso que separa IADD de "IA que escreve código".

| | IA gerando código direto | **IADD** |
|---|---|---|
| Artefato versionado | o código | **o mapa** (e o gerador) |
| Repetibilidade | nenhuma — cada geração difere | total — mesma entrada, mesma saída |
| Onde se corrige um defeito sistêmico | em N arquivos | **em 1 gerador**, e regenera-se N |
| Onde a IA erra | no código entregue | no mapa ou no gerador — **antes** do código |
| Validação | revisão humana / testes | **o CLI valida o mapa**; testes validam o código |
| Custo de contexto | o código inteiro | o mapa (tipicamente ~50% menor que XML equivalente) |

**O que IADD não é**: não é *scaffolding* de uma vez só. O gerador é reexecutado durante toda a vida do
projeto — a saída é **sobrescrita por inteiro**, sempre. Nenhuma edição manual em arquivo gerado sobrevive.
Essa é a restrição que organiza todo o resto do método (§6).

---

## 1. As duas portas de entrada

Um projeto entra em IADD por um de dois caminhos. Confundi-los é o erro de adoção mais caro, porque o segundo
parece o primeiro e não é.

### Porta A — projeto novo (modela do zero)

Não existe mapa. O domínio é extraído de histórias de usuário, entrevistas ou documentação, e modelado
diretamente em `.mi`. Dono: o arquétipo **`domain-mapper`**, guiado pelo guia de modelagem de domínio.

### Porta B — projeto com mapas `.mm` ativos (converte)

Quem já usa Mapper Idea em FreeMind tem domínio modelado há anos em `.mm`. **Remodelar do zero é a parede que
impede a adoção** — e é desnecessária:

```sh
xsltproc tools/mm-to-mi/exportMI.xsl <arquivo>.mm | sed 's/§/ /g' > <arquivo>.mi
```

A conversão é real, não hipotética: foi ela que produziu os packs de geradores que existem hoje. Sobre 1,31 MB
de mapas reais, a redução média foi de **53% em bytes** (a economia em tokens tende a ser maior — XML tokeniza
pior e o `.mm` carrega *bookkeeping* de editor que é ruído puro para a IA).

**A conversão não termina no `.mi` gerado. Termina na validação do DOM** (§4). Duas armadilhas conhecidas:

- o `@mode` real no DOM **pode divergir** do que o mapeamento de ícones do FreeMind sugere — só se descobre
  inspecionando o DOM com `struct`;
- ícone que a tabela de conversão não conhece **passa cru, em silêncio**. Converta em lote com relatório e
  leia o relatório.

| | Porta A | Porta B |
|---|---|---|
| Primeiro passo | modelar a primeira entidade | converter a árvore `.mm` |
| Primeiro risco | modelar o que não se entendeu | achar que converteu porque o arquivo existe |
| Primeiro gate | `push` + `load` passam **e** o `struct` mostra o que se esperava | idem — e o relatório da conversão foi lido |

---

## 2. As etapas

```
  ┌──────────────────────────────────────────────────────────────────────────────┐
  │  história de usuário / requisito / mapa .mm existente                        │
  └────────────────────────────────┬─────────────────────────────────────────────┘
                                   │  domain-mapper
                                   ▼
  ┌──────────────────────────────────────────────────────────────────────────────┐
  │  MAPA DE NEGÓCIO  ·  mi/<contexto>/*.mi   ([b] entidades, [c] tipos auxiliares)│
  │  tipos em linguagem de NEGÓCIO (Texto, Data, ValorMonetario) — nunca técnicos │
  └────────────────────────────────┬─────────────────────────────────────────────┘
                                   │  cli-runner:  mi push <projeto>  →  mi load <projeto>
                                   ▼
  ┌──────────────────────────────────────────────────────────────────────────────┐
  │  DOM NORMALIZADO  (na nuvem)                                                 │
  │  /classes/class[@name][@package][@mode]/attributes/attribute[@type][@mode]   │
  │  ← a ÚNICA fonte de verdade sobre a forma do dado. Inspecionável com `struct`│
  └────────────────────────────────┬─────────────────────────────────────────────┘
                                   │  generator-author (observa o DOM, escreve o gerador)
                                   ▼
  ┌──────────────────────────────────────────────────────────────────────────────┐
  │  MAPA DE ARQUITETURA  ·  mi/generators/**/*.mi  (+ registro no main.mi)       │
  │  parameters · vars · fragments · patterns · start · templates                │
  └────────────────────────────────┬─────────────────────────────────────────────┘
                                   │  cli-runner:  mi generate <proj> <grupo> <sub> … > destino
                                   ▼
  ┌──────────────────────────────────────────────────────────────────────────────┐
  │  CÓDIGO-ALVO  (sobrescrito por inteiro a cada geração)                       │
  └────────────────────────────────┬─────────────────────────────────────────────┘
                                   │  test-engineer / build do projeto
                                   ▼
  ┌──────────────────────────────────────────────────────────────────────────────┐
  │  TESTES + BUILD  ← o gate que prova que o gerador está certo, não o código   │
  └──────────────────────────────────────────────────────────────────────────────┘
```

Cada etapa tem entrada, saída e **gate de saída** — o que precisa ser verdade para passar adiante:

| Etapa | Entrada | Saída | Gate de saída |
|---|---|---|---|
| 1. Modelagem | história / `.mm` | `mi/<contexto>/*.mi` | checklist de qualidade da entidade + registro no `main.mi` |
| 2. Normalização | mapa de negócio | DOM | `push` enviou e `load` passa — legível, ainda não validado |
| 3. Observação | DOM | entendimento da forma | `struct` mostra os atributos/`properties` que o gerador vai casar — **é aqui que o mapa se valida** |
| 4. Autoria do gerador | DOM + convenções da stack | `mi/generators/**` | checklist do gerador (§7) |
| 5. Geração | gerador + mapa | código | saída **não vazia** e sintaticamente válida |
| 6. Verificação | código | confiança | build/typecheck/testes do projeto passam |

**A etapa 3 não é opcional.** Escrever `match`/`select` sem ter olhado o DOM é a causa nº 1 de gerador que
produz saída vazia — e o mais caro dos erros, porque falha em silêncio (§4).

---

## 3. Quem é dono de cada etapa, e as fronteiras duras

IADD divide o trabalho em **três papéis com fronteiras não-negociáveis**. Não é organograma: é o mecanismo
que impede os modos de falha conhecidos.

| Arquétipo | Papel | Escreve | Lê | Roda o CLI |
|---|---|---|---|---|
| **`domain-mapper`** | modela o negócio | `mi/<contexto>/*.mi` | histórias, glossário, guia DDD | **não** |
| **`generator-author`** | escreve os geradores | `mi/generators/**` + `main.mi` | mapas de negócio, DOM | **não** |
| **`cli-runner`** | opera e valida | **nada** (só inspeciona) | tudo | **sim** |

**Por que as fronteiras são duras** — cada uma existe por um modo de falha observado:

1. **O modelador não escreve gerador.** Senão, uma lacuna do modelo vira remendo no template, e o mapa deixa
   de descrever o negócio. O mapa é o documento de negócio; se ele mente, tudo abaixo mente.
2. **O autor de gerador não edita o mapa de negócio.** Senão, o modelo passa a ser moldado pela conveniência
   do gerador — a cauda balançando o cachorro.
3. **Quem escreve não valida.** O `cli-runner` não tem ferramenta de escrita: ele roda `push`/`load`/`compile`/`struct`/`generate`
   e **reporta o texto exato** do resultado. Quem escreveu o artefato tem viés para interpretar erro como
   "provavelmente é outra coisa".
4. **Nenhum dos três inventa a forma do DOM.** Quando o `generator-author` precisa saber como um atributo
   aparece, ele **pede o `struct`** ao `cli-runner`. Não deduz do `.mi` — o `.mi` e o DOM não são a mesma
   árvore (os grupos visuais `[g]`, por exemplo, são achatados na normalização).

Em equipe humana os três papéis podem ser a mesma pessoa; as fronteiras continuam valendo como **disciplina
de etapa**: modele, depois valide, depois gere — nunca as três ao mesmo tempo.

---

## 4. Onde a validação real acontece — e por que `grep` engana

### A cadência

```sh
cd mi/ && mi init <projeto> main.mi     # UMA vez — vincula nome do projeto → pasta do mapa principal
mi push <projeto>                        # a CADA alteração de qualquer .mi (negócio E geradores)
mi generate <projeto> <grupo> <sub> modelName=<Classe> package=<pkg> > <destino>   # N vezes
```

**O `init` roda dentro da pasta do mapa principal**, e o segundo argumento é só o nome do arquivo — não
um caminho. A pasta onde ele roda vira a *home* do projeto: os caminhos `#` dos mapas são relativos a ela,
e o `push` envia o que está dentro dela. `mi init <projeto> sub/main.mi` rodado da pasta de cima registra
uma home diferente da que os mapas esperam, e o projeto se perde.

Depois do `init`, o registro é **global, pelo nome do projeto**: tudo roda de qualquer diretório. É isso
que deixa mapas e código viverem separados — o projeto de código pode consumir mais de um projeto Mapper
Idea, cada um na sua pasta, e o código gerado não precisa levar junto os mapas nem os geradores que o
produziram.
**Regra**: editou `.mi`, fez `push` antes de qualquer outro comando. Sem exceção — tudo o que vem depois
acontece **no servidor**, sobre a última versão enviada; sem `push`, você valida e gera o mapa de antes.

### O `push` envia; quem valida é a geração

`mi push` **não valida**: ele só leva os mapas para a nuvem. É essencial — sem ele nada do que vem depois
enxerga a sua edição —, mas "o `push` passou" não diz nada sobre o conteúdo do mapa.

A validação acontece quando o servidor **lê** o mapa, e há uma escada de comandos para isso. Cada degrau
refaz os anteriores e acrescenta um; subir degrau a degrau serve para **isolar** onde está o erro:

| Degrau | Comando | O que prova quando passa | Quem usa |
|---|---|---|---|
| 1 | `mi check <projeto>` | o que foi enviado chegou inteiro e está acessível para o seu usuário | diagnóstico |
| 2 | `mi load <projeto>` | o mapa principal e os mapas ligados a ele foram lidos e viraram o DOM normalizado | depois de mexer no mapa de negócio |
| 3 | `mi compile <projeto> <grupo> <sub>` | o gerador compila contra o mapa — sem gerar nada | depois de mexer num gerador |
| 4 | `mi generate <projeto> struct xml className=<C> packageName=<p>` | a classe tem a **forma** que se pretendia | a validação de referência do mapa |
| 5 | `mi generate <projeto> <grupo> <sub> …` | o gerador roda sobre uma classe real | a validação do gerador |

Os erros vêm como `EMI…` com o texto do problema — leia o texto, não só o código.

**Os degraus 2 e 3 passarem não basta**: eles provam que o mapa é *legível* e o gerador *compilável*, não
que dizem o que você quis dizer. Um link para um mapa que não existe **não falha** o `load` — vira um nó
vazio, em silêncio —, e uma propriedade `@` fora do vocabulário é descartada sem aviso. Só o `struct` mostra
isso. Por isso a regra de conduta do `cli-runner` é:

> **Se você não rodou `struct` na classe, você não afirma que o mapa está válido.** "O `push` passou" não é
> validação, e "validado por `grep`" também não.

### O `struct` é o microscópio

```sh
mi generate <projeto> struct xml className=<Classe> packageName=<pkg> > /tmp/<classe>-struct.xml
```

Despeja o DOM normalizado da classe. É como se verifica: atributo esperado apareceu? `@type`, `@mode`,
`@typeParameter` e `cn` estão como se pretendia? Os valores de enum entraram sob `properties/values`?
O relacionamento virou `oneToOne`/`manyToOne`/`oneToMany` como se esperava?

**O achado mais valioso do `struct` é o campo que sumiu.** O DOM materializa um vocabulário conhecido de
propriedades; uma chave inventada no bloco `@` é **descartada em silêncio** — nada avisa.

### Os quatro enganos que só o CLI desfaz

| Sintoma | O que parece | O que é |
|---|---|---|
| **Saída vazia + exit 0** | "o gerador rodou, só não tinha o que gerar" | `start match` não casou, ou uma expressão de `var` abortou a compilação. O erro real (`EMI…`) aparece no `compile` ou no `generate` — nunca no `push`, que não lê o gerador. Também dá saída vazia, sem erro nem com `-d`: caminho `#` fora da home do `mi init` (ver o checklist do §7), sub-gerador, `modelName` ou `package` inexistentes. E o `EMI…` sai no **stdout**, com exit 0 — redirecionado com `>`, fica escrito **dentro** do arquivo gerado: depois de gerar, `grep -rl 'EMI[0-9]'` na saída. |
| **Propriedade `@` não faz efeito** | "o gerador ignora essa prop" | a prop não existe no DOM — foi descartada na normalização por não estar no vocabulário conhecido |
| **Dois templates casam o mesmo nó** | "ele pega o primeiro" | prioridade **igual** → o motor usa o **último** em ordem de documento. Nunca confie na ordem: torne os `match` mutuamente exclusivos. |
| **Campo existe no `.mi` e não no código** | "bug do gerador" | o campo caiu na normalização — está ausente do DOM, o gerador nunca teve o que casar |

Todos os quatro **passam por uma leitura de código e por qualquer `grep`**. Nenhum passa pelo `struct`.

---

## 5. O loop de desenvolvimento de um gerador

```
1. push                    envia o mapa atual para a nuvem (não valida)
2. struct <Classe>         inspeciona a forma real: attribute/@type, @mode, properties/…
3. escreve/ajusta          match, apply-templates, dispatch por tipo
4. generate numa entidade REAL, para arquivo
5. lê a saída              vazia? sintaticamente inválida? @TODO inesperado?
6. volta ao 1
```

Três disciplinas que este loop carrega:

- **struct-first** — nenhum `match` é escrito antes de a forma do nó ter sido vista (§4).
- **dispatch por dicionário, nunca hardcoded** — as famílias de tipo vivem no bloco `config`/`maps` do
  `main.mi` e são consumidas no gerador via `vars`. Tipo novo se resolve **adicionando ao dicionário**, não
  com um caso especial no template. Esse bloco é o *seam* do DSL: é onde uma convenção de stack é declarada
  uma vez e lida por todos os geradores.
- **TODO-on-unhandled** — todo modo termina com um `match` genérico que emite um comentário
  `// @TODO tipo não tratado`. **Nó desconhecido vira comentário visível no código gerado; nunca quebra a
  geração e nunca some.** É o que transforma um buraco silencioso em item de trabalho.

---

## 6. Quando o gerado diverge do que se escreveria à mão

Este é o momento em que projetos abandonam a geração: alguém edita o arquivo gerado "só desta vez", a próxima
geração apaga a edição, e a conclusão vira "o gerador atrapalha". **A saída é sobrescrita por inteiro — por
construção, não por descuido.** Diante de uma divergência, a decisão é uma destas quatro, nunca uma quinta:

| A divergência é… | Onde se corrige | Não faça |
|---|---|---|
| **defeito do gerador** (saída errada para um caso que ele deveria cobrir) | no gerador, e regenera | editar o output |
| **lacuna do mapa** (o modelo não expressa a intenção — falta uma prop, um enum, um relacionamento) | no mapa de negócio, `push`, regenera | codificar a exceção no template |
| **caso único e legítimo** (regra que existe numa entidade só e não é padrão) | fora do caminho da geração: lib de runtime, subclasse, "ilha" de código próprio | ramificar o gerador por nome de entidade |
| **convenção nova da stack** (tipo, mapeamento, nomenclatura) | no bloco `config`/`maps` do `main.mi` | tratar caso a caso no template |

Duas regras que acompanham:

- **Ao corrigir um defeito numa variante, varra as demais.** Geradores de família (create/read/update/delete;
  page/form/columns) compartilham lógica: um bug numa quase sempre existe nas irmãs.
- **Customização não mora em lógica imperativa dentro do mapa.** Mora na lib de runtime ou numa ilha. Mapa
  que vira programa deixa de ser documento de negócio — e o mapa como documento legível é metade do valor.

---

## 7. Como nasce um pack de stack novo

Um **pack** é o conjunto de geradores de uma stack (ex.: `quarkus/`, `frontend/`). É o que faz um projeto
novo começar com CRUD, API e telas em vez de com um "hello world".

Um pack é **semente, não dependência**: quem adota copia, adapta e passa a ser dono. Não há canal de
atualização, e isso é decisão de produto, não limitação. O que o pack transporta de mais valioso **não é o
código emitido — é a demonstração de como se observa o mapa, se faz o dispatch e se emite o alvo**. Quem for
para outra stack não vai *usar* o pack existente: vai *lê-lo*.

### Passos

1. **Escolha uma entidade real** do projeto-alvo como caso de prova (não um exemplo de brochura).
2. **Rode `struct` nela.** A forma do DOM é o contrato de entrada do pack inteiro.
3. **Escreva o gerador mais simples da família primeiro** — o que emite um arquivo por classe, sem
   relacionamento. Ele estabelece o esqueleto (`parameters`, `vars`, `patterns`, `start`, `templates`).
4. **Declare as famílias de tipo no `maps`** antes de precisar da segunda delas.
5. **Cresça por dispatch, não por cópia**: cada família de tipo é um `template` no modo, com `match`
   mutuamente exclusivo, e o genérico `@TODO` fecha a lista.
6. **Só então ataque relacionamento** — `[r]`, `[m]`/`[o]` e, sobretudo, **relação aninhada**, que é o ponto
   cego mais comum: um XPath que só olha o atributo de topo perde classes referenciadas transitivamente.

### Checklist de "pronto"

```
[ ] Sub-gerador registrado no main.mi, com caminho # relativo, sob <grupo>/<sub>
    (relativo à HOME do projeto — a pasta onde se rodou `mi init` —, não ao arquivo que o contém;
    `../` não funciona, porque o push só envia o que está sob a home: check e push passam, e todo
    generate sai vazio com exit 0)
    (a invocação do CLI são 2 tokens: <grupo> <sub> — não crie 3 níveis)
[ ] parameters declarados (por-entidade: modelName + package)
[ ] DOM real inspecionado via struct — os match conferem com a forma normalizada
[ ] Dispatch cobre todas as famílias de tipo usadas pelas entidades-alvo
[ ] Sem overlap de match (predicados de exclusão onde dois templates poderiam casar o mesmo nó)
[ ] Nó não tratado emite @TODO — nunca quebra, nunca some
[ ] README de contrato: "o que seu mapa precisa ter para eu gerar" + "o que aqui é do projeto de
    origem e você vai querer trocar" (namespace, nomenclatura, libs)
[ ] Exemplo executável versionado no pack: mapa mínimo NÃO-domínio (3–4 entidades, um
    relacionamento fraco, um enum) cujo generate produz projeto que COMPILA — e cuja saída foi
    LIDA: `@JoinColumn(name="")` compila (ver packs/quarkus/exemplo/)
[ ] Versão e data carimbadas no README (quem copiou pode diffar contra uma versão mais nova)
```

O exemplo executável não é gate de regressão de produto mantido — é a **prova de que o pack funciona fora do
projeto que o gerou** e, de quebra, o tutorial de entrada.

---

## 8. As três camadas dentro de cada artefato

Nada no kit se divide em "genérico" vs "do projeto X". Cada arquivo — agente, gerador, guia — mistura três
coisas, e saber separá-las é o que torna o método transportável:

| Camada | O que é | Transfere? |
|---|---|---|
| **Método** | o ofício: o pipeline, a disciplina struct-first, o dispatch por dicionário, os checklists | **sim, verbatim** |
| **Domínio** | entidades, máquinas de estado, regras de negócio, personas | **não** — re-extrai no destino |
| **Fiação** | caminhos, namespaces, IDs de tracker, convenções de repo, branch | **não** — parametriza ou sinaliza |

Copiar um agente carregado de domínio para outro projeto e trocar os nomes produz um agente que **fala com
autoridade sobre regras que não existem lá** — pior que não ter agente. O mesmo vale para gerador: um gerador
Quarkus que assume o namespace do projeto de origem não é um pack de stack, é um pack daquele projeto.

---

## 9. Glossário mínimo

| Termo | O que é |
|---|---|
| **Mapa de Negócio** | `.mi` que descreve entidades e atributos em linguagem de negócio. Documento de domínio, legível por quem não programa. |
| **Mapa de Arquitetura** | `.mi` que descreve um **gerador**: casa nós do DOM e emite texto. Dialeto XSLT-like. |
| **DOM normalizado** | a árvore que o servidor monta a partir dos mapas enviados pelo `push` (o `load` para nela; todo `generate` passa por ela). Fonte de verdade da forma do dado. Não é idêntica ao `.mi`. |
| **`struct`** | gerador do pack padrão que despeja o DOM de uma classe em XML. O microscópio do método, e a validação de referência do mapa. É um gerador como os outros: precisa estar **registrado no `main.mi`** — sem registro, `mi g … struct` sai vazio e sem erro. No kit: `packs/_exemplar/generators/struct.mi`. |
| **pack** | conjunto de geradores de uma stack. Semente, não dependência. |
| **seam** (`config`/`maps`) | o bloco do `main.mi` onde convenções e dicionários de tipo são declarados uma vez e lidos por todos os geradores. |
| **ilha** | trecho de código escrito à mão que vive **fora** do caminho da geração, porque a saída é sobrescrita por inteiro. |

---

## Apêndice — o ciclo inteiro em comandos

```sh
# uma vez, por projeto
cd mi/ && mi init meuprojeto main.mi

# porta B: trazendo mapas .mm existentes
xsltproc tools/mm-to-mi/exportMI.xsl dominio.mm | sed 's/§/ /g' > mi/dominio/Dominio.mi

# a cada alteração de mapa (negócio OU gerador) — envia, não valida
mi push meuprojeto

# mexeu no mapa de negócio: ele é legível?
mi load meuprojeto

# mexeu num gerador: ele compila?
mi compile meuprojeto quarkus entity

# validar o mapa, e observar antes de escrever gerador
mi generate meuprojeto struct xml className=Pedido packageName=com.exemplo.dominio > /tmp/pedido.xml

# gerar
mi generate meuprojeto quarkus entity modelName=Pedido package=com.exemplo.dominio \
  > backend/src/main/java/com/exemplo/entity/PedidoEntity.java

# verificar de verdade
./gradlew build     # ou mvn test, npm run typecheck… o build do projeto é o gate final
```

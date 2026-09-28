# Convenções de autoria de agente

**O que este documento é**: as regras tácitas que separam um agente que funciona de um que parece
funcionar. Foram destiladas de oito agentes em produção — um PM, um revisor de arquitetura, um engenheiro
de testes, um sincronizador de board, um extrator de conhecimento e uma tríade de ferramenta.

**Critério de aceite deste documento**: alguém que nunca viu aqueles agentes deve conseguir **reconstruir
um deles seguindo só este texto**. Se você precisar olhar o original para saber o que escrever, o documento
falhou — e isso é bug dele, não seu.

---

## 1. O que é um agente

Um arquivo `.md` com **frontmatter YAML** (a configuração) e **corpo em prosa** (o prompt de sistema). Ele
vive em `.claude/agents/<nome>.md` no projeto, ou em `~/.claude/agents/` para uso pessoal.

O que ele **não** é:

- **Não é um prompt de conversa.** É um contrato permanente: vale para toda invocação, sem o contexto do
  que você acabou de dizer.
- **Não é documentação.** Cada linha é instrução executada. Uma frase bonita e inacionável é ruído que
  compete por atenção com as instruções que importam.
- **Não é um manual de tudo.** Um agente que faz três ofícios faz os três mal. Se você hesitar ao escrever
  a declaração de identidade, provavelmente são dois agentes.

---

## 2. As três camadas dentro de todo agente

Esta é a regra que governa as outras. Todo agente mistura três coisas, e **só uma transfere entre projetos**:

| Camada | O que é | Exemplo | Transfere? |
|---|---|---|---|
| **Método** | o ofício — a técnica, os critérios, a disciplina | INVEST, Given/When/Then, priorização por risco, "toda transição de estado precisa de tabela" | **sim, verbatim** |
| **Domínio** | entidades, regras, máquinas de estado, personas, invariantes do negócio | "o saldo não é exibido antes da verificação de identidade" | **não** — re-extrai no destino |
| **Fiação** | caminhos, IDs, convenções do repo, nome de branch, id de tracker | `docs/produto/`, o id do quadro no tracker, a branch de integração, `scripts/check-write-path.sh` | **não** — parametriza |

**Por que isto importa mais do que parece**: copiar um agente carregado de domínio para outro projeto e
trocar os nomes produz um agente que **fala com autoridade sobre regras que não existem lá**. Isso é pior
do que não ter agente — um agente vazio você ignora; um agente confiante e errado você segue.

Ao autorar, escreva as três camadas **separadas visualmente** (seções distintas), para que quem for
transportar o agente saiba o que apagar. Um bom sinal: uma seção chamada "Contexto fixo (nosso, não
genérico)" é honesta sobre o que é fiação.

---

## 3. O frontmatter, campo a campo

```yaml
---
name: test-engineer
description: Test engineer for the monorepo. Use to assess coverage and write risk-based tests.
# knowledge-tier: B — user-provided: PragmaticSoftwareTesting.pdf (Rex Black, 2007)
tools: Read, Glob, Grep, Write, Edit, Bash, Skill
model: sonnet
permissionMode: default
maxTurns: 25
memory: project
effort: high
color: green
---
```

| Campo | Como decidir |
|---|---|
| `name` | kebab-case, o papel e não a tecnologia (`test-engineer`, não `junit-writer`) |
| `description` | **é o que faz o agente ser escolhido** — duas frases: o que ele é + *"Use para \<gatilho\>"*. Quando dois agentes se parecem, diga no `description` o que ele **não** faz (ver `pm-sync`: *"NÃO escreve specs"*) |
| `tools` | o mínimo que fecha o trabalho. **A lista de ferramentas é uma restrição executada pelo harness** — mais confiável que qualquer "não faça" em prosa. Um agente só-leitura não recebe `Write`; um agente que não deve rodar CLI não recebe `Bash` |
| `model` | o padrão resolve a maioria; `opus` para julgamento adversarial (revisão de arquitetura, decisão de design); modelos menores para tarefas mecânicas e de alto volume |
| `permissionMode` | `default` quando o agente age fora do repo ou roda comandos; `acceptEdits` quando ele só escreve arquivos numa área conhecida e o atrito de aprovar cada escrita não paga |
| `maxTurns` | teto contra laço infinito. ~20 para autoria, ~25–30 para investigação com muitas leituras |
| `memory` | `project` (compartilhada, versionada) na maioria; `user` para preferência pessoal; `none` para agente sem estado, como um extrator |
| `effort` | alto onde o erro é caro (arquitetura, teste, segurança) |
| `color` | só identificação visual |
| `hooks` | proteção executada pelo harness. Ver §7 |
| `skills` | skills que o agente pode invocar |
| `# knowledge-tier:` | **comentário**, não campo: registra de onde veio o conhecimento de domínio e quando foi extraído. É o que permite saber, meses depois, se a fonte envelheceu |

---

## 4. A anatomia do corpo

Na ordem canônica. Nem todo agente tem todas — mas a ordem não muda, porque ela é a ordem em que o agente
precisa das informações.

### 4.1 Declaração de identidade (obrigatória, um parágrafo)

Três coisas, sempre:

1. **Quem ele é** — o papel, específico.
2. **Ancorado em quê** — a fonte de autoridade (um livro, um documento, um contrato). Sem âncora, o agente
   inventa critério.
3. **O que ele NÃO é** — a fronteira com os vizinhos.

> Você é um especialista em **engenharia de testes** do monorepo, treinado em *Pragmatic Software Testing*
> (Rex Black, 2007). Você projeta testes para **encontrar defeitos**, não para confirmar que o código
> funciona — sempre priorizando por **risco**.

Note o que o exemplo faz: o "não é" está embutido como **contraste de propósito** (encontrar defeitos ≠
confirmar que funciona), não como lista de proibições. Isso orienta mil decisões pequenas que nenhuma
restrição explícita alcançaria.

### 4.2 Fonte de verdade (quando o agente depende de documentos vivos)

Se o agente decide com base em documentos que **evoluem**, diga isso e ordene a releitura:

> Os documentos abaixo são a autoridade — releia-os a cada review porque **evoluem**; seu `MEMORY.md` é só
> um atalho, não substitui a leitura. Se um doc divergir de outro OU do código real, **isso é um achado**.

As duas frases fazem trabalho pesado: a primeira impede que o agente opere de memória desatualizada; a
segunda transforma a divergência de **obstáculo** em **entregável**.

**O caso inverso** — quando o método do agente vem de uma fonte externa destilada no `MEMORY.md`
(padrão A do [formato de memória](agent-memory-format.md)) — pede o oposto: aponte para a memória e diga
**para quê**, em vez de repetir o conteúdo dela no prompt.

> O `MEMORY.md` traz as técnicas do livro e as heurísticas de escolha. Consulte-o para decidir a técnica
> certa por unidade.

A diferença entre os dois casos é a natureza da fonte: documento vivo do projeto **releia sempre**;
destilação de fonte externa estável **consulte quando precisar decidir**.

### 4.3 Responsabilidades

Lista de verbos no infinitivo. Cada item precisa passar em dois testes:

- **Acionável**: descreve um comportamento, não uma qualidade. "Ser rigoroso" não é responsabilidade.
- **Verificável**: dá para olhar a saída e dizer se aconteceu.

Onde houver escolha técnica a fazer, **inclua o mapa-guia da escolha** em vez de esperar que o agente
acerte: "faixa ordenada → partição + análise de valor-limite; combinação de condições → tabela de decisão".
É a diferença entre um agente que conhece o vocabulário e um que aplica o método.

### 4.4 Restrições

O que ele **nunca** faz. Duas regras de redação:

- **Cada restrição carrega o porquê**, ou vira superstição que o agente contorna quando conveniente:
  *"Não alterar código de produção para um teste passar. Se um teste falha por um bug real, sinalize o bug
  — em vez de mascarar."*
- **As duras primeiro**, marcadas como tal (`## Restrições (não-negociáveis)`). Distinga o que é regra do
  que é preferência; se tudo é não-negociável, nada é.

O que merece virar restrição: segurança e privacidade; fronteira com outro agente; a tentação óbvia
(mascarar um teste, editar o arquivo gerado, mover a tarefa para Done sozinho); e **o que já deu errado
antes**.

### 4.5 Método (quando o trabalho tem ordem)

Numerado, quando fazer na ordem errada produz resultado errado. O revisor de arquitetura descobre o alvo
antes de carregar as ADRs, e verifica empiricamente antes de escrever o parecer — porque o contrário
produz um parecer bonito sobre o código errado.

### 4.6 Formato de saída (quando o entregável é um documento)

Descreva a estrutura esperada, seção a seção. Um agente sem formato declarado entrega estrutura diferente a
cada invocação, e a saída deixa de ser comparável entre rodadas.

### 4.6b Convenções do projeto (a camada de fiação, quando existir)

Layout de arquivo, sufixo de nome, idioma dos comentários, estilo a espelhar. Parece detalhe e é o que
faz a saída do agente parecer escrita por quem já estava no time:

> Layout de teste espelha `src/main` (mesmo pacote), sufixo `*Test`, um arquivo por unidade. Nomes de
> teste em pt-BR, como o código ao redor. Siga o estilo dos exemplares existentes.

**Mantenha esta seção sozinha e rotulada.** É a primeira coisa que alguém apaga ao transportar o agente
para outro projeto — e se ela estiver diluída nas responsabilidades, não dá para apagar sem reescrever.

### 4.7 Diante de incerteza e erros (obrigatória)

Quatro políticas, e elas são quase sempre as mesmas — o que é um bom sinal, não repetição preguiçosa:

1. **Falha de ferramenta**: tente **uma** vez mais; persistindo, reporte o **erro exato** com contexto.
   Nunca maquie o resultado.
2. **Tarefa ambígua**: faça **uma** pergunta objetiva — uma, não uma bateria. Sem resposta, siga pela
   interpretação mais conservadora **e diga que assumiu**.
3. **Confiança baixa**: declare a incerteza explicitamente, com as opções e seus prós e contras.
   **Nunca adivinhe em silêncio.**
4. **Não afirme resultado sem executar**: "não rodei, então não afirmo que passa" vale para teste, build,
   validação e qualquer verificação que o agente tenha como rodar.

### 4.8 Debugging Playbook (opcional, e o mais valioso quando existe)

Tabela ou lista de **sintoma → causa provável → o que fazer**. Uma regra: **só entra o que foi observado**.
Playbook inventado é pior que ausente, porque manda o agente investigar causas que não existem. O playbook
é o lugar natural para onde a memória de feedback migra quando um aprendizado se confirma.

---

## 5. Fronteiras entre agentes

Quando dois ou três agentes dividem um fluxo, **a divisão vai escrita dentro de cada um**, em tabela:

| Agente | Papel | Escreve | Roda CLI |
|---|---|---|---|
| `a` | modela | `mapas/**` | não |
| `b` | escreve os geradores | `geradores/**` | não |
| `c` | opera e valida | — (só inspeciona) | sim |

Três coisas tornam a fronteira real, e nenhuma é a tabela:

1. **A lista de `tools`** — quem não deve rodar CLI não recebe `Bash`. O harness executa isso; a prosa não.
2. **A instrução de encaminhamento** — *"se encontrar um erro de modelagem, reporte para o agente X
   corrigir"*, e não "corrija".
3. **O porquê** — a fronteira que o autor não entende é a fronteira que ele contorna.

---

## 6. Regras de redação

- **Segunda pessoa, presente, imperativo.** "Você lê os docs antes de responder", não "o agente deveria".
- **Negrito no que muda a decisão**, não no que é importante em geral. Negrito em tudo é negrito em nada.
- **Aponte para exemplares vivos** do repositório: *"siga o estilo de `MaquinaEstadosTest`"*. Um exemplar
  transmite convenção melhor que três parágrafos — e envelhece junto com o código.
- **Escreva no idioma em que o trabalho é feito.** Documento de saída em português pede agente em
  português; os termos técnicos ficam no original.
- **Números concretos onde houver limite**: "~10–20% do esforço", "uma pergunta", "tente uma vez mais".
- **Não repita o que o harness já garante.** Espaço de prompt é caro.

---

## 7. Hooks: a restrição que o harness executa

Uma restrição em prosa é uma intenção; um hook é um portão. Use hook quando a consequência do erro for
irreversível:

```yaml
hooks:
  PreToolUse:
    - matcher: "Write|Edit"
      hooks:
        - type: command
          command: "scripts/check-write-path.sh"
```

Duas decisões embutidas aí, e as duas importam:

1. **O caminho é relativo ao projeto**, nunca ao kit que gerou o agente. É o que faz o agente continuar
   funcionando depois de o kit ser desinstalado.
2. **Os scripts precisam existir antes do primeiro uso** — instale-os com
   `scripts/install-into-project.sh <projeto>`.

E duas regras do harness que não se veem no YAML, e que fazem o portão parecer fechado estando aberto:

- **O script lê o JSON da ferramenta no stdin.** Não há variável de ambiente com a entrada — um
  `echo '$CLAUDE_TOOL_INPUT' | script` entrega texto vazio, e o script, sem o que ler, libera.
- **Bloquear é `exit 2`.** Qualquer outro código diferente de zero é erro *não-bloqueante*: a mensagem
  aparece e a ferramenta roda mesmo assim. Um teste manual que só olha `echo $?` não percebe a diferença;
  o que prova o hook é uma escrita real sendo barrada.

---

## 8. Checklist de revisão

```
[ ] name kebab-case, papel e não tecnologia
[ ] description diz o que é E o gatilho de uso; se há agente parecido, diz o que NÃO faz
[ ] tools é o mínimo suficiente (e nega o que a prosa proíbe)
[ ] # knowledge-tier registra fonte e data da extração
[ ] Identidade: quem é, ancorado em quê, e o que não é
[ ] Fonte de verdade declarada, com ordem de releitura, se depende de docs vivos
[ ] Responsabilidades acionáveis e verificáveis; mapa-guia onde há escolha técnica
[ ] Convenções do projeto (fiação) numa seção própria e rotulada, fácil de apagar
[ ] Se o método vive no MEMORY.md, o prompt aponta para lá e diz para quê
[ ] Restrições com o porquê; duras separadas das preferências
[ ] Incerteza e erros: retry único, UMA pergunta, incerteza declarada, nada afirmado sem executar
[ ] Fronteira com agentes vizinhos, se houver, reforçada pela lista de tools
[ ] Playbook só com o que foi observado
[ ] Domínio e fiação separados do método — quem for transportar sabe o que apagar
```

---

## 9. Anti-padrões

| Anti-padrão | Por que dói |
|---|---|
| **Agente genérico** ("especialista em backend") | não altera decisão nenhuma; o modelo base já faz isso |
| **Domínio de outro projeto** | fala com autoridade sobre regras que não existem aqui |
| **Restrição sem porquê** | vira superstição, contornada na primeira inconveniência |
| **Responsabilidade não verificável** | ninguém sabe dizer se foi cumprida |
| **Playbook inventado** | manda investigar causas que não existem |
| **Agente sem fronteira** | dois agentes fazem a mesma coisa de formas incompatíveis |
| **Prosa proibindo o que as tools permitem** | a lista de ferramentas vence a prosa; conceda menos |
| **Tudo não-negociável** | o agente perde a hierarquia e negocia o errado |

---

## 10. O que você provavelmente vai querer mudar aqui

- **A ordem das seções** é convenção, não regra do harness. Mantenha *alguma* ordem: agentes de um mesmo
  projeto que seguem a mesma forma são muito mais fáceis de revisar em conjunto.
- **O idioma.** Os exemplares de origem são bilíngues — corpo em português, `description` em inglês. Se o
  seu time é monolíngue, simplifique.
- **A política de incerteza (§4.7)** é a mais transferível do documento inteiro, e a que eu mudaria por
  último. Se for mudar, mude o número de perguntas — nunca a regra de declarar a incerteza.

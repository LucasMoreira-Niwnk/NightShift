# Trabalhando no NIGHTSHIFT

## Preparar outra máquina

Instale Git e Godot **4.0.stable padrão** (GDScript; não precisa de .NET, Blender ou Node para jogar). Cada pessoa deve usar sua própria conta GitHub e ter permissão de escrita no repositório, concedida pelo proprietário em Settings > Collaborators.

No PowerShell:

```powershell
git clone https://github.com/LucasMoreira-Niwnk/NightShift.git
cd NightShift
git config user.name "Seu nome"
git config user.email "Seu email verificado no GitHub ou email noreply da sua conta"
New-Item -ItemType Directory -Force .local | Out-Null
Set-Content .local/godot-path.txt 'C:\caminho\para\Godot_v4.0-stable_win64_console.exe' -Encoding UTF8
.\'Abrir Editor.cmd'
```

Substitua o caminho pelo executável extraído do Godot. Esse arquivo fica ignorado pelo Git. Aguarde a importação dos assets no primeiro início e pressione F5. Também é possível importar `game/project.godot` diretamente no editor. Os assets necessários já estão incluídos.

## Uma branch por tarefa

Comece com a árvore de trabalho limpa (`git status`). Atualize a main antes de criar sua branch:

```powershell
git switch main
git pull --ff-only origin main
git switch -c feat/minha-tarefa
```

Combinem quem altera cada script ou cena, principalmente os arquivos que montam o cenário. Evitem editar o mesmo arquivo ao mesmo tempo. Façam commits pequenos, com nomes que descrevam a mudança.

Depois das alterações, valide mudanças de comportamento:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\godot.ps1 -Mode check
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\godot.ps1 -Mode test
git status
git diff
git add caminho/do/arquivo
git diff --cached
git commit -m "Descreve a mudança"
git push -u origin feat/minha-tarefa
```

Troque os exemplos pelos nomes reais. No primeiro push, o Git Credential Manager pode solicitar login pelo navegador; use sua própria conta. Abra um pull request para `main` no GitHub e peça ao colega que revise. Depois do merge, atualize a main local com `git pull --ff-only origin main`.

Se houver conflito, preservem as duas contribuições, resolvam os trechos indicados pelo Git e validem novamente antes de concluir. Não usem push forçado na main.

## O que versionar

Inclua código, cenas, assets, arquivos de configuração de importação (`.import`) e créditos/licenças. O cache `.godot/`, dados pessoais e saves em `.local/`, builds e credenciais ficam fora do repositório. Não é necessário instalar Git LFS para os assets atuais. Não inclua o executável do Godot.

Os scripts auxiliares `.mjs` são ferramentas opcionais de preparação de assets; não fazem parte das dependências do jogo. Ao adicionar assets externos, registre origem e licença em `game/assets/ART_CREDITS.md`.

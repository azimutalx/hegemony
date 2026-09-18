"""Monta o pacote do cliente Hegemony para mandar aos amigos.

    py tools/empacotar.py                        # joga na propria maquina
    py tools/empacotar.py --endereco 100.64.1.2  # IP do Tailscale do anfitriao
    py tools/empacotar.py --mods <pasta>         # junta uma pasta mods/ de fora

Sai um .zip em ../../hegemony-pacotes/ (fora do repositorio: sao ~300 MB).

O pacote leva so o que o cliente carrega: o executavel (runtime estatico, nao
depende de DLL fora do Windows), init.lua, config.otml, modules/ e data/ sem
os assets de outras versoes. Ficam de fora bin/ e binaries/ (clientes oficiais
antigos), tools/, logs e executaveis de backup.

O endereco troca a linha Hegemony_Host do init.lua e o host do config.otml.
Ele so funciona se o servidor anunciar o mesmo endereco (CANARY_SERVER_IP no
docker/.env): o login devolve o IP do mundo, e e nele que o cliente conecta
para jogar.

--mods copia uma pasta de fora deste repositorio para Hegemony/mods/ no zip:
modulos extras e um servidores_extras.lua, que o init.lua le se existir.
"""
import argparse
import re
import zipfile
from datetime import date
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
PASTA_NO_ZIP = "Hegemony"
VERSAO = "1525"

# Dentro de data/, estas pastas tem uma subpasta por versao do cliente; so a
# nossa vai.
POR_VERSAO = {"things", "sounds"}

LEIA_ME = """Hegemony - cliente
==================

1. Extraia esta pasta inteira em qualquer lugar (ex.: Documentos).
2. Abra Hegemony.exe.
3. Na tela de login escolha o servidor na lista.
4. Entre com o email e a senha da sua conta. Conta nova: "Criar conta"
   abre o site do servidor escolhido.

Os servidores rodam na maquina de um amigo, dentro da rede do Tailscale.
Instale o Tailscale (tailscale.com), entre com o convite que voce recebeu e
deixe ele ligado enquanto joga. Sem isso o login nao conecta.

Endereco configurado neste pacote: {endereco}
"""


def arquivos_do_pacote(mods):
    yield RAIZ / "otclient.exe", "Hegemony.exe"
    for nome in ("init.lua", "config.otml"):
        yield RAIZ / nome, nome
    for caminho in sorted((RAIZ / "modules").rglob("*")):
        if caminho.is_file():
            yield caminho, caminho.relative_to(RAIZ).as_posix()
    data = RAIZ / "data"
    for caminho in sorted(data.rglob("*")):
        if not caminho.is_file():
            continue
        partes = caminho.relative_to(data).parts
        if partes[0] in POR_VERSAO and (len(partes) < 2 or partes[1] != VERSAO):
            continue
        yield caminho, caminho.relative_to(RAIZ).as_posix()
    if mods:
        for caminho in sorted(mods.rglob("*")):
            if caminho.is_file():
                yield caminho, "mods/" + caminho.relative_to(mods).as_posix()


def com_endereco(caminho, texto, endereco):
    if caminho.name == "init.lua":
        novo, n = re.subn(r'^Hegemony_Host = ".*"$', f'Hegemony_Host = "{endereco}"',
                          texto, flags=re.M)
    else:
        novo, n = re.subn(r"^host: http://[^:/]+", f"host: http://{endereco}", texto, flags=re.M)
    if n != 1:
        raise SystemExit(f"nao achei onde trocar o endereco em {caminho.name}; o pacote nao foi gerado")
    return novo


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--endereco", default="127.0.0.1", help="IP ou nome da maquina dos servidores")
    ap.add_argument("--saida", default=str(RAIZ.parent.parent / "hegemony-pacotes"))
    ap.add_argument("--mods", help="pasta a copiar para mods/ dentro do pacote")
    args = ap.parse_args()
    mods = Path(args.mods) if args.mods else None
    if mods and not mods.is_dir():
        raise SystemExit(f"--mods: {mods} nao e uma pasta")

    if not (RAIZ / "data" / "things" / VERSAO).is_dir():
        raise SystemExit(f"faltam os assets em data/things/{VERSAO}")

    saida = Path(args.saida)
    saida.mkdir(parents=True, exist_ok=True)
    sufixo = "local" if args.endereco == "127.0.0.1" else args.endereco.replace(":", "_")
    destino = saida / f"Hegemony-cliente-{date.today():%Y-%m-%d}-{sufixo}.zip"

    total = 0
    quantos = 0
    with zipfile.ZipFile(destino, "w", zipfile.ZIP_DEFLATED, compresslevel=6) as z:
        for origem, nome in arquivos_do_pacote(mods):
            alvo = f"{PASTA_NO_ZIP}/{nome}"
            if nome in ("init.lua", "config.otml"):  # os da raiz; mods/ nao passa aqui
                texto = origem.read_text(encoding="utf-8")
                z.writestr(alvo, com_endereco(origem, texto, args.endereco))
            else:
                # Sprites e sons ja vem comprimidos (lzma/ogg): comprimir de
                # novo so gasta tempo.
                ja_comprimido = origem.suffix in (".lzma", ".ogg", ".png", ".jpg")
                z.write(origem, alvo, compress_type=zipfile.ZIP_STORED if ja_comprimido else zipfile.ZIP_DEFLATED)
            total += origem.stat().st_size
            quantos += 1
        z.writestr(f"{PASTA_NO_ZIP}/LEIA-ME.txt", LEIA_ME.format(endereco=args.endereco))

    print(f"{quantos} arquivos, {total / 2**20:.0f} MB sem compressao")
    print(f"pacote: {destino} ({destino.stat().st_size / 2**20:.0f} MB)")


if __name__ == "__main__":
    main()

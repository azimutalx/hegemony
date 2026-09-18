"""Gera as texturas do tema "brasa e ferro" do cliente Hegemony.

A paleta sai da arte de fundo (modules/client_background): carvao quente,
bronze, brasa e ouro. As imagens sao 9-slice: o cliente estica o miolo e
preserva as bordas, entao o que importa e o tamanho das bordas bater com o
`image-border` declarado em data/styles/10-windows.otui e 10-buttons.otui.

Rode de novo sempre que mudar a paleta:  py tools/gerar_tema.py  (precisa de Pillow)
"""
from pathlib import Path
from PIL import Image, ImageDraw

RAIZ = Path(__file__).resolve().parent.parent
SAIDA = RAIZ / "data" / "images" / "ui" / "hegemony"
SAIDA.mkdir(parents=True, exist_ok=True)

CARVAO_TOPO = (30, 23, 19)
CARVAO_BASE = (16, 12, 10)
BRONZE = (104, 70, 44)
BRONZE_ESCURO = (44, 31, 24)
BRASA = (196, 82, 44)
OURO = (214, 170, 92)


def gradiente(img, caixa, cima, baixo, alfa=255):
    x0, y0, x1, y1 = caixa
    d = ImageDraw.Draw(img)
    altura = max(1, y1 - y0)
    for y in range(y0, y1):
        t = (y - y0) / altura
        cor = tuple(round(cima[i] + (baixo[i] - cima[i]) * t) for i in range(3)) + (alfa,)
        d.line([(x0, y), (x1 - 1, y)], fill=cor)


def cantos_de_ouro(img, tamanho=3):
    d = ImageDraw.Draw(img)
    w, h = img.size
    for x, y in [(0, 0), (w - tamanho, 0), (0, h - tamanho), (w - tamanho, h - tamanho)]:
        d.rectangle([x, y, x + tamanho - 1, y + tamanho - 1], fill=OURO + (255,))


def janela(nome, com_titulo):
    # Bordas: 6 nas laterais e embaixo; 27 no topo quando ha barra de titulo.
    w = h = 256
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    topo = 27 if com_titulo else 6
    gradiente(img, (1, topo, w - 1, h - 1), CARVAO_TOPO, CARVAO_BASE, alfa=242)
    d = ImageDraw.Draw(img)
    if com_titulo:
        gradiente(img, (1, 1, w - 1, topo), (70, 30, 18), (36, 17, 11), alfa=250)
        d.line([(1, topo - 1), (w - 2, topo - 1)], fill=BRASA + (255,))
        d.line([(1, topo), (w - 2, topo)], fill=(70, 40, 24, 255))
    d.rectangle([0, 0, w - 1, h - 1], outline=BRONZE + (255,))
    d.rectangle([1, 1, w - 2, h - 2], outline=BRONZE_ESCURO + (255,))
    cantos_de_ouro(img)
    img.save(SAIDA / nome)


def botao(nome, largura=96, altura=24):
    # Tres estados empilhados: normal, hover, pressionado. Borda 4.
    estados = [
        ((128, 38, 20), (78, 22, 12), BRASA, (210, 120, 80)),
        ((160, 50, 26), (100, 28, 14), (232, 120, 70), (240, 160, 110)),
        ((70, 20, 11), (104, 30, 16), (142, 53, 32), (120, 60, 40)),
    ]
    img = Image.new("RGBA", (largura, altura * len(estados)), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for i, (cima, baixo, borda, brilho) in enumerate(estados):
        y0 = i * altura
        gradiente(img, (1, y0 + 1, largura - 1, y0 + altura - 1), cima, baixo)
        d.line([(2, y0 + 1), (largura - 3, y0 + 1)], fill=brilho + (140,))
        d.rectangle([0, y0, largura - 1, y0 + altura - 1], outline=borda + (255,))
    img.save(SAIDA / nome)


def campo(nome, largura=64, altura=24):
    # Campo de texto: fundo quase preto, borda bronze. Estado 2 = com foco (brasa).
    img = Image.new("RGBA", (largura, altura * 2), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for i, borda in enumerate([BRONZE, BRASA]):
        y0 = i * altura
        d.rectangle([0, y0, largura - 1, y0 + altura - 1], fill=(12, 9, 8, 235), outline=borda + (255,))
        d.line([(1, y0 + 1), (largura - 2, y0 + 1)], fill=(0, 0, 0, 200))
    img.save(SAIDA / nome)


def seta(d, cx, cy, cor):
    # Triangulo apontando para baixo, 7 px de largura.
    for i in range(4):
        d.line([(cx - 3 + i, cy + i), (cx + 3 - i, cy + i)], fill=cor + (255,))


def combobox(nome, largura=128, altura=24):
    # Tres estados empilhados: normal, hover, aberto. A seta mora nos 22 px da
    # direita, que o otui declara como image-border-right para nao esticar.
    img = Image.new("RGBA", (largura, altura * 3), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for i, (borda, cor_seta) in enumerate([(BRONZE, OURO), (BRASA, (240, 200, 130)), (BRASA, BRASA)]):
        y0 = i * altura
        d.rectangle([0, y0, largura - 1, y0 + altura - 1], fill=(12, 9, 8, 235), outline=borda + (255,))
        d.line([(1, y0 + 1), (largura - 2, y0 + 1)], fill=(0, 0, 0, 200))
        d.line([(largura - 22, y0 + 4), (largura - 22, y0 + altura - 5)], fill=BRONZE_ESCURO + (255,))
        seta(d, largura - 11, y0 + altura // 2 - 2, cor_seta)
    img.save(SAIDA / nome)


def caixa_marcar(nome, lado=14):
    # Estados empilhados: desmarcada, marcada, marcada desabilitada.
    img = Image.new("RGBA", (lado, lado * 3), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for i, miolo in enumerate([None, BRASA, BRONZE]):
        y0 = i * lado
        d.rectangle([0, y0, lado - 1, y0 + lado - 1], fill=(12, 9, 8, 235), outline=BRONZE + (255,))
        if miolo:
            d.rectangle([3, y0 + 3, lado - 4, y0 + lado - 4], fill=miolo + (255,))
            d.line([(4, y0 + 4), (lado - 5, y0 + 4)], fill=(240, 160, 110, 180))
    img.save(SAIDA / nome)


def fundo():
    # A arte original era JPEG com extensao .png: o cliente so le PNG e falhava
    # calado, mostrando so os veus escuros por cima. Aqui sai PNG de verdade,
    # com um escurecimento a direita (onde fica o login) e vinheta em cima e
    # embaixo, no lugar dos dois veus de tela cheia que apagavam a imagem.
    origem = RAIZ / "tools" / "arte" / "fundo-original.jpg"
    arte = Image.open(origem).convert("RGBA")
    w, h = arte.size
    sombra = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = sombra.load()
    inicio = int(w * 0.60)
    for x in range(inicio, w):
        a = int(150 * (((x - inicio) / (w - inicio)) ** 1.3))
        for y in range(h):
            px[x, y] = (8, 5, 4, a)
    for y in range(h):
        d = min(y, h - 1 - y) / (h * 0.18)
        if d < 1:
            extra = int(70 * (1 - d))
            for x in range(w):
                r, g, b, a0 = px[x, y]
                px[x, y] = (8, 5, 4, min(255, a0 + extra))
    destino = RAIZ / "modules" / "client_background" / "background.png"
    Image.alpha_composite(arte, sombra).convert("RGB").save(destino, format="PNG", optimize=True)


janela("window.png", com_titulo=True)
janela("window_headless.png", com_titulo=False)
botao("button.png")
campo("textedit.png")
combobox("combobox.png")
caixa_marcar("checkbox.png")
fundo()
print("texturas em", SAIDA)
for f in sorted(SAIDA.iterdir()):
    print(" ", f.name, Image.open(f).size)

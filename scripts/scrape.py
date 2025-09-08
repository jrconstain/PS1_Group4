# Importar librerías
import requests
from bs4 import BeautifulSoup
import pandas as pd

# ===============================
# ========= Data Dictionary =====
# ===============================

# Traer el HTML y parsearlo con Beautiful Soup
url_dictionary = "https://ignaciomsarmiento.github.io/GEIH2018_sample/dictionary.html"
dictionary = requests.get(url_dictionary)

# Parsear el HTML con BeautifulSoup y encontrar la tabla
dictionary = BeautifulSoup(dictionary.text, "html.parser")
dictionary = dictionary.find("table")

# Extraer encabezados
headers = [th.text.strip() for th in dictionary.find("tr").find_all("th")]

# Extraer filas de datos
rows = []
for tr in dictionary.find_all("tr")[1:]:
    cells = [td.text.strip() for td in tr.find_all("td")]
    if cells:  # Evitar filas vacías
        rows.append(cells)

# Convertir a DataFrame
dictionary = pd.DataFrame(rows, columns=headers)
dictionary.to_csv('../stores/dictionary.csv', index=False)

# Evidenciar scrapping exitoso
print("Scrapping exitoso del diccionario de datos ✅")
print(f"Se recuperaron {dictionary.shape[0]} filas y {dictionary.shape[1]} variables")
print(dictionary.head())
print(dictionary.shape)

# ===============================
# ========= Data Labels =========
# ===============================

# Traer el HTML y parsearlo con Beautiful Soup
url_labels = "https://ignaciomsarmiento.github.io/GEIH2018_sample/labels.html"
labels = requests.get(url_labels)

# Parsear el HTML con BeautifulSoup y encontrar la tabla
labels = BeautifulSoup(labels.text, "html.parser")
labels = labels.find("table")

# Extraer encabezados
headers = [th.text.strip() for th in labels.find("tr").find_all("th")]

# Extraer filas de datos
rows = []
for tr in labels.find_all("tr")[1:]:
    cells = [td.text.strip() for td in tr.find_all("td")]
    if cells:  # Evitar filas vacías
        rows.append(cells)

# Convertir a DataFrame
labels = pd.DataFrame(rows, columns=headers)
labels.to_csv('../stores/labels.csv', index=False)

# Evidenciar scrapping exitoso
print("Scrapping exitoso de las etiquetas de datos ✅")
print(f"Se recuperaron {labels.shape[0]} filas y {labels.shape[1]} variables")
print(labels.head())
print(labels.shape)

# ===============================
# ========= Data Scrapping ======
# ===============================

import os
from pathlib import Path
from selenium import webdriver
from selenium.webdriver.common.by import By
from bs4 import BeautifulSoup
import pandas as pd
from time import sleep


from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException, NoSuchElementException, StaleElementReferenceException


import random

# Parámetros
BASE_URL = "https://ignaciomsarmiento.github.io/GEIH2018_sample/page{n}.html"
DATA_DIR = Path("../stores/raw")
DATA_DIR.mkdir(parents=True, exist_ok=True)

XPATH_TABLE = '/html/body/div/div/div[2]/div/table'

def scrape_one_page(n: int) -> pd.DataFrame:
    """
    Abre un driver nuevo, espera correctamente a que cargue la página y la tabla,
    extrae la tabla con TU XPath exacto y cierra el driver. Devuelve el DataFrame.
    Incluye reintentos para evitar NoSuchElement/Timeout/StaleElement.
    """
    print(f"[INFO] Iniciando scraping de page{n}...")
    driver = None
    attempts = 3  # reintentos

    try:
        for attempt in range(1, attempts + 1):
            driver = webdriver.Chrome()
            url = f"https://ignaciomsarmiento.github.io/GEIH2018_sample/page{n}.html"
            driver.set_page_load_timeout(30)

            try:
                driver.get(url)

                # 1) Esperar a que el documento termine de cargar
                WebDriverWait(driver, 20).until(
                    lambda d: d.execute_script("return document.readyState") == "complete"
                )

                # Pequeño jitter para evitar carreras esporádicas
                sleep(0.2 + random.random() * 0.6)

                # 2) Esperar PRESENCIA y VISIBILIDAD de la tabla por XPath (tu selector exacto)
                WebDriverWait(driver, 15).until(
                    EC.presence_of_element_located((By.XPATH, XPATH_TABLE))
                )
                WebDriverWait(driver, 15).until(
                    EC.visibility_of_element_located((By.XPATH, XPATH_TABLE))
                )

                # 3) (Opcional recomendado) Esperar a que haya >1 fila en la tabla
                def table_has_rows(d):
                    try:
                        return d.execute_script(
                            """
                            const t = document.evaluate(arguments[0], document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue;
                            if (!t) return false;
                            return t.querySelectorAll('tr').length > 1;
                            """,
                            XPATH_TABLE
                        )
                    except Exception:
                        return False

                WebDriverWait(driver, 10).until(table_has_rows)

                # --- Tu lógica EXACTA de extracción a partir del XPath ---
                table_element = driver.find_element(By.XPATH, XPATH_TABLE)
                html_content = table_element.get_attribute('outerHTML')

                soup = BeautifulSoup(html_content, 'html.parser')
                table = soup.find('table')

                headers = [th.text.strip() for th in table.find('tr').find_all('th')]

                rows = []
                for tr in table.find_all('tr')[1:]:
                    cells = [td.text.strip() for td in tr.find_all('td')]
                    if cells:
                        rows.append(cells)

                data_df = pd.DataFrame(rows, columns=headers)
                # -------------------------------------------------------

                print(f"[OK] page{n} scrape exitoso. Dimensiones: {data_df.shape[0]} filas x {data_df.shape[1]} columnas.")
                return data_df

            except (TimeoutException, NoSuchElementException, StaleElementReferenceException) as e:
                print(f"[WARN] Intento {attempt}/{attempts} falló en page{n}: {type(e).__name__} -> {e}")
                try:
                    driver.refresh()
                    # Darle un respiro y reintentar en el siguiente loop
                    sleep(1.0 + random.random())
                except Exception:
                    pass
            finally:
                if driver is not None:
                    driver.quit()
                    print(f"[INFO] Driver cerrado para page{n} (intento {attempt}).")
                    driver = None

        # Si llegamos aquí, fallaron todos los intentos
        raise RuntimeError(f"No fue posible obtener la tabla de page{n} tras {attempts} intentos.")

    except Exception as e:
        print(f"[ERROR] Falló page{n}: {e}")
        raise

def save_page_csv(df: pd.DataFrame, n: int) -> Path:
    out_path = DATA_DIR / f"page{n}.csv"
    df.to_csv(out_path, index=False, encoding="utf-8")
    print(f"[OK] Guardado stores/raw/page{n}.csv ✅ ({df.shape[0]} filas, {df.shape[1]} columnas)")
    return out_path

def next_pages_to_run(start: int = 1, end: int = 10):
    """
    Devuelve la lista de páginas a correr. Si algún CSV ya existe, se omite.
    Permite reanudar en caso de interrupción (skip a lo que ya existe).
    """
    to_run = []
    for n in range(start, end + 1):
        if (DATA_DIR / f"page{n}.csv").exists():
            print(f"[SKIP] Ya existe sotres/raw/page{n}.csv. Omitiendo.")
        else:
            to_run.append(n)
    return to_run

def all_pages_present(start: int = 1, end: int = 10) -> bool:
    return all((DATA_DIR / f"page{n}.csv").exists() for n in range(start, end + 1))

def combine_all(start: int = 1, end: int = 10, outname: str = "data.csv"):
    """
    Combina page{start}..page{end} en un único CSV en orden.
    """
    if not all_pages_present(start, end):
        missing = [n for n in range(start, end + 1) if not (DATA_DIR / f"page{n}.csv").exists()]
        print(f"[WARN] No se puede combinar. Faltan: {missing}")
        return

    frames = []
    for n in range(start, end + 1):
        path = DATA_DIR / f"page{n}.csv"
        df = pd.read_csv(path, dtype=str)  # dtype=str para evitar sorpresas al concatenar
        frames.append(df)

    big = pd.concat(frames, axis=0, ignore_index=True)
    out_path = DATA_DIR / outname
    big.to_csv(out_path, index=False, encoding="utf-8")

    print(f"[SUCCESS] stores/raw/{outname} creado con éxito ✅")
    print(f"[INFO] Dimensiones finales: {big.shape[0]} filas x {big.shape[1]} columnas")

def main():
    # Determinar qué páginas quedan por correr (reanudable)
    pages = next_pages_to_run(1, 10)

    if not pages:
        print("[INFO] No hay páginas pendientes de scraping. Pasando a combinar si aplica...")
    else:
        for n in pages:
            try:
                df = scrape_one_page(n)
                save_page_csv(df, n)
                # Pequeña pausa opcional para evitar saturar (puedes ajustar o quitar)
                sleep(0.5)
            except Exception as e:
                print(f"[FATAL] Se detuvo en page{n}. Motivo: {e}")
                print("[INFO] Puedes re-ejecutar este script; retomará desde la siguiente pendiente.")
                return  # Salir sin combinar para que puedas reintentar

    # Si ya están todas las páginas, combinar
    if all_pages_present(1, 10):
        combine_all(1, 10, "data.csv")
    else:
        faltantes = [n for n in range(1, 11) if not (DATA_DIR / f"page{n}.csv").exists()]
        print(f"[WARN] Aún faltan páginas por scrape: {faltantes}. No se generó data.csv.")

if __name__ == "__main__":
    main()

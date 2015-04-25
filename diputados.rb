require "watir-webdriver"
require "nokogiri"
require 'json'

browser = Watir::Browser.new :chrome

browser.goto "http://www.servidorespublicos.gob.mx"
browser.link(:text, 'Búsqueda').click

diputados = ["Enrique Peña Nieto"]
#id de las tablas para buscar en declaracion y generar json

tablas = ["ServPub","Encargo","escolaridad","ExpLab","Logros","DecAnterior", "Acuerdo", "IngresoDec", "IngresoDec2", "BienInmueble", "Vehiculo","BienMueble", "Inversiones","adeudo", "gastos"]

funcionariosPublicos = []
funcionario = {}
diputados.each do |diputado|
	browser.text_field(:id, 'formBusquedaServPub:txtNombre').set diputado
	browser.button(:text, "Buscar").click
	if(not(browser.label(:text,"No se encontró ningún registro").exists?))
		
		#nombre del diputado en mayusculas
		browser.tr(:class, "renglon_par_tabla").td(:index,1).text

		#le pica al boton con el nombre del primer elemeento de la columna que es el nombre del diputado en mayusculas
		browser.link(:text, browser.tr(:class, "renglon_par_tabla").td(:index,0).text).click
		
		#fecha
		browser.tr(:class, "renglon_par_tabla").td(:index,2)

		#click en la declaracion despues de guardar la fecha
		browser.tr(:class, "renglon_par_tabla").td(:index,3).link(:text, "Declaración").click
		sleep 3
		p browser.title
		browser.windows.last.use


		#informacion del encabezado
		html_doc = Nokogiri::HTML(browser.html)
		encabezado = html_doc.css("table#encabezado font[size='2']")
		encargoData = html_doc.css("table#Encargo font[size='1']")
		escolaridadData = html_doc.css("table#escolaridad > tbody > tr")
		labroalData = html_doc.css("table#ExpLab > tbody > tr")
		bienData = html_doc.css("table#BienInmueble >tbody >tr")
		bienMData = html_doc.css("table#BienMueble >tbody >tr")
		inversionesData = html_doc.css("table#Inversiones >tbody >tr")


		json_funcionario = {}
		# dataEncabezado["nombre"] = encabezado[0].content.strip

		auxEncabezado = {}
		encabezado.each do |data|
			if data.content.strip.include? ":"
				arr = data.content.strip.split ":"
				auxEncabezado[arr[0].delete(" ").downcase] = arr[1].strip
			else
				auxEncabezado["nombre"] = data.content.strip
			end

		end
		json_funcionario["informacionGral"] = auxEncabezado

		auxEncargo = {}
		key = ""
		encargoData.each do |data|
			if (data.content.strip.count ":") > 1
				auxEncargo[key.delete(" ")] = data.content.strip.delete(":")
			elsif data.content.strip.include? ":"
				key = data.content.strip.delete(":").downcase
			elsif data.content.strip.include? "?"
				key = data.content.strip.delete("?").downcase
			else
				auxEncargo[key.delete(" ")] = data.content.strip
			end	
		end
		json_funcionario["datosPuesto"] = auxEncargo

		auxEscolaridad = {}
		keys = []
		arrAux = []
		escolaridadData[5].css("td").each do |data|
			keys.push(data.content.strip.downcase.delete(" "))
		end

		(6..escolaridadData.length-1).each do |index|
			escolaridadData[index].css("td").each_with_index do |data, i|
				if auxEscolaridad[keys[i]].nil?
					auxEscolaridad[keys[i]] = []
				end
				auxEscolaridad[keys[i]].push(data.content.strip.downcase.delete("\"").delete("\n"))
			end
		end

		json_funcionario["escolaridad"] = auxEscolaridad


		auxLaboral = {}
		keys = []
		arrAux = []
		labroalData[3].css("td").each do |data|
			keys.push(data.content.strip.downcase.delete(" "))
		end

		(4..labroalData.length-1).each do |index|
			labroalData[index].css("td").each_with_index do |data, i|
				if auxLaboral[keys[i]].nil?
					auxLaboral[keys[i]] = []
				end
				auxLaboral[keys[i]].push(data.content.strip.downcase.delete("\n"))
			end
		end

		json_funcionario["epecienciaLaboral"] = auxLaboral


		auxBien = {}
		keys = []
		arrAux = []
		bienData[3].css("td").each do |data|
			keys.push(data.content.strip.downcase.delete(" "))
		end

		(4..bienData.length-1).each do |index|
			bienData[index].css("td").each_with_index do |data, i|
				if auxBien[keys[i]].nil?
					auxBien[keys[i]] = []
				end
				auxBien[keys[i]].push(data.content.strip.downcase.delete("\n"))
			end
		end

		json_funcionario["bienesInmuebles"] = auxBien


		auxBienM = {}
		keys = []
		arrAuxM = []
		bienMData[3].css("td").each do |data|
			keys.push(data.content.strip.downcase.delete(" "))
		end

		(4..bienMData.length-1).each do |index|
			bienMData[index].css("td").each_with_index do |data, i|
				if auxBienM[keys[i]].nil?
					auxBienM[keys[i]] = []
				end
				auxBienM[keys[i]].push(data.content.strip.downcase.delete("\n"))
			end
		end

		json_funcionario["bienesMuebles"] = auxBienM

		auxInversiones = {}
		keys = []
		arrAuxI = []
		inversionesData[3].css("td").each do |data|
			keys.push(data.content.strip.downcase.delete(" "))
		end

		(4..inversionesData.length-1).each do |index|
			inversionesData[index].css("td").each_with_index do |data, i|
				if auxInversiones[keys[i]].nil?
					auxInversiones[keys[i]] = []
				end
				auxInversiones[keys[i]].push(data.content.strip.downcase.delete("\n"))
			end
		end

		json_funcionario["inversiones"] = auxInversiones
		# p json_funcionario
		funcionariosPublicos.push(json_funcionario)
	end
	File.open("./funcionarios.json", 'w') { |file| file.write(funcionariosPublicos.to_json) }
end

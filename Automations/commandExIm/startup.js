module.exports = {
  run: (options) => {
    const fs = require("node:fs")
    const path = require("node:path")
    const { dialog, shell } = require("electron")

    function showDonatePopup() {
      return new Promise((resolve) => {
        const overlay = document.createElement("div")
        overlay.style.cssText = `
      position: fixed; inset: 0; background: rgba(0,0,0,0.6);
      z-index: 9999;
    `

        const modal = document.createElement("div")
        modal.style.cssText = `
          position: fixed;
          top: calc(50vh - 120px);
          left: calc(50vw - 250px);
          background: #1e1e2e;
          color: #fff;
          padding: 48px;
          border-radius: 12px;
          width: 500px;
          text-align: center;
          box-shadow: 0 8px 32px rgba(0,0,0,0.4);
          z-index: 10000;
          font-family: sans-serif;
        `

        modal.innerHTML = `
          <h2 style="margin:0 0 8px">❤️ Enjoy this drag and drop to import feature?</h2>
          <p style="margin:0 0 24px; color:#aaa">Consider making a donation to support development!</p>
          <div style="display:flex; gap:12px; justify-content:center">
            <button id="noThanks" style="padding:10px 20px; border-radius:8px; border:1px solid #555;
              background:transparent; color:#aaa; cursor:pointer; font-size:14px">
              No Thanks
            </button>
            <button id="donateBtn" style="padding:10px 20px; border-radius:8px; border:none;
              background:#5865f2; color:#fff; cursor:pointer; font-size:14px; font-weight:600">
              💖 Donate
            </button>
          </div>
        `

        document.body.appendChild(overlay)
        document.body.appendChild(modal)

        const cleanup = () => {
          overlay.remove()
          modal.remove()
        }

        document.getElementById("noThanks").onclick = () => {
          cleanup()
          resolve("no")
        }

        document.getElementById("donateBtn").onclick = () => {
          cleanup()
          shell.openExternal("https://ko-fi.com/slothyacedia")
          resolve("donate")
        }
      })
    }

    let titleCase = (string) =>
      string
        .split(" ")
        .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
        .join(" ")

    if (options.result) {
      let element = document.createElement("div")
      element.classList = "hoverablez option"
      element.innerHTML = `Export/Import`
      element.onclick = () => {
        options.eval('runAutomation("commandExIm")')
      }
      element.id = "commandExImQA"

      let elementAnchor = document.getElementById("collaborationStatus")

      element.appendAfter(elementAnchor)

      let commandBar = document.getElementById("commandbar")

      let originalClr = commandBar.style.borderColor

      let validateCmdJSON = (commandJSON) => {
        if (typeof commandJSON.name != "string") {
          return false
        }

        if (typeof commandJSON.type != "string") {
          return false
        }

        if (typeof commandJSON.trigger != "string") {
          return false
        }

        if (!Array.isArray(commandJSON.actions)) {
          return false
        }

        if (typeof commandJSON.customId != "number") {
          return false
        }

        return true
      }

      commandBar.addEventListener("dragover", (event) => {
        event.preventDefault()
        commandBar.style.borderColor = "#00b4d8"
      })

      commandBar.addEventListener("dragleave", () => {
        commandBar.style.borderColor = originalClr
      })

      commandBar.addEventListener("drop", async (event) => {
        event.preventDefault()
        if (event.dataTransfer.files.length == 0) {
          return
        }
        let dataJSONPath = path.join(process.cwd(), "AppData", "data.json")
        let preferenceFilePath = path.join(process.cwd(), "Automations", "commandExIm", "preferences.json")
        let botData = JSON.parse(fs.readFileSync(dataJSONPath))
        let commands = botData.commands
        commandBar.style.borderColor = originalClr
        let files = Array.from(event.dataTransfer.files)
        let importCount = 0
        let jsonFiles = files.filter((f) => f.name.toLowerCase().endsWith(".json"))

        if (jsonFiles.length < 1) {
          return
        }

        await Promise.all(
          jsonFiles.map(async (file) => {
            try {
              const fileContent = await file.text()
              const commandJSON = JSON.parse(fileContent)
              if (validateCmdJSON(commandJSON)) {
                commands.push(commandJSON)
                importCount++
              } else {
                console.log(`Invalid Command JSON In ${file.name}`)
              }
            } catch (err) {
              console.log(`Failed To Parse ${file.name}:`, err)
            }
          }),
        )
        botData.commands = commands
        fs.writeFileSync(dataJSONPath, JSON.stringify(botData, null, 2), "utf8")

        if (importCount > 0) {
          if (!fs.existsSync(preferenceFilePath)) {
            fs.mkdirSync(path.dirname(preferenceFilePath), { recursive: true })
            let defaultDataStructure = {
              export: "",
              importDnD: 0,
            }
            fs.writeFileSync(preferenceFilePath, JSON.stringify(defaultDataStructure, null, 2))
          }
          let preferencesRaw = fs.readFileSync(preferenceFilePath)
          let preferences = JSON.parse(preferencesRaw)
          preferences.importDnD = (Number(preferences.importDnD) || 0) + importCount
          if (preferences.importDnD >= 10 && !preferences.donoPopup) {
            preferences.importDnD = Number(preferences.importDnD) % 10
            await showDonatePopup()
          }
          fs.writeFileSync(preferenceFilePath, JSON.stringify(preferences, null, 2))
          try {
            options.result(titleCase(`✅ ${importCount} Command${importCount > 1 ? "s" : ""} Imported Successfully, Reloading...`))
          } catch {}
          setTimeout(() => location.reload(), 1000)
        } else {
          try {
            options.result(titleCase(`⚠️ No Commands Imported`))
          } catch {}
        }
      })
    }
  },
}

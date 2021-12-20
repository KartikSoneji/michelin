const dasha = require("@dasha.ai/sdk");
const fs = require("fs");
const https = require("https");
const cheerio = require("cheerio");

async function main() {
  const app = await dasha.deploy("./app");

  app.ttsDispatcher = () => "dasha";

  app.connectionProvider = async (conv) =>
    conv.input.phone === "chat"
      ? dasha.chat.connect(await dasha.chat.createConsoleChat())
      : dasha.sip.connect(new dasha.sip.Endpoint("default"));

  const recipe = await getRecipieData("https://www.allrecipes.com/recipe/246553/bakery-style-pizza/");

  app.setExternal("getListLength", async ({ list }) => {
    return recipe[list].length;
  });

  app.setExternal("getListItem", async ({ list, index }) => {
    return recipe[list][index] ?? `Sorry, invalid ${list} id ${index}`;
  });

  await app.start();

  const conv = app.createConversation({ phone: process.argv[2] ?? "chat", item: "pizza" });

  if (conv.input.phone !== "chat") conv.on("transcription", console.log);

  const logFile = await fs.promises.open("./log.txt", "w");
  await logFile.appendFile("#".repeat(100) + "\n");

  conv.on("transcription", async (entry) => {
    await logFile.appendFile(`${entry.speaker}: ${entry.text}\n`);
  });

  conv.on("debugLog", async (event) => {
    if (event?.msg?.msgId === "RecognizedSpeechMessage") {
      const logEntry = event?.msg?.results[0]?.facts;
      await logFile.appendFile(JSON.stringify(logEntry, undefined, 2) + "\n");
    }
  });

  const result = await conv.execute();
  console.log(result.output);

  await app.stop();
  app.dispose();

  await logFile.close();
}

main();

async function getRecipieData(url){
    const html = await fetch(url).then(e => e.text());
    const $ = cheerio.load(html);

    let ingredients = $("span.ingredients-item-name")
        .map(function (i, el) {
            return $(this).text();
        })
        .toArray();
    let steps = $("div.paragraph")
        .map(function (i, el) {
            return $(this).text();
        })
        .toArray();
    return {
        ingredients, steps
    };
}

async function fetch(url, options = {}){
	return new Promise((resolve, reject) => {
		let req = https.request(url, options, res => {
			let data = [];
			res.on("data", d => data.push(d));
			res.on("end", e => {
				let rawData = Buffer.concat(data).toString();
				resolve({
					headers: res.headers,
					status: res.statusCode,
					url,
					text: async () => rawData,
					json: async () => JSON.parse(rawData)
				})
			});
		});

		req.on("error", reject);

		let body = options.body;
		if(typeof body != "string")
			body = JSON.stringify(body);
		if(body && options.method != "GET" && options.method != "HEAD")
			req.write(body);

		req.end();
	});
}

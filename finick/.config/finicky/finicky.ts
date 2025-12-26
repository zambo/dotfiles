import type { FinickyConfig } from "/Applications/Finicky.app/Contents/Resources/finicky.d.ts";

const config: FinickyConfig = {
	defaultBrowser: "Google Chrome",
	handlers: [
		{
			// Open these urls in Chrome
			match: ["*.youtube.com/*", "*.youtu.be/*", "youtube.com/*", "youtu.be/*"],
			browser: "Arc",
		},
	],
};

export default config;

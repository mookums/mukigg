import tailwindcss from "@tailwindcss/vite";
import wasm from "vite-plugin-wasm";
import topLevelAwait from "vite-plugin-top-level-await";
import EleventyVitePlugin from "@11ty/eleventy-plugin-vite";

import syntaxHighlight from "@11ty/eleventy-plugin-syntaxhighlight";
import { DateTime } from "luxon";

export default async function(eleventyConfig) {
  eleventyConfig.setInputDirectory("src");
  eleventyConfig.addPassthroughCopy("src/assets");

  eleventyConfig.addPlugin(EleventyVitePlugin, {
    viteOptions: {
      plugins: [tailwindcss(), wasm(), topLevelAwait()],
    }
  });
  eleventyConfig.addPlugin(syntaxHighlight);

  eleventyConfig.addFilter("date", (dateObj, format) => {
    return DateTime.fromJSDate(dateObj).toFormat(format);
  })
}

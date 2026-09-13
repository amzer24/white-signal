import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath, pathToFileURL} from 'node:url';
const root=path.dirname(fileURLToPath(import.meta.url));
const modulePath=process.argv[2];
if(!modulePath) throw new Error('Pass the installed marked module path.');
const {marked}=await import(pathToFileURL(modulePath).href);
for(const relative of ['EXPLORATION-DESIGN.md','notes/effects.md','notes/story-arc.md']){
 const src=path.join(root,relative), sub=relative.startsWith('notes/');
 let md=fs.readFileSync(src,'utf8');
 md=md.replace(/^\[\^(\d+)\]: (.*)$/gm,(_,n,t)=>`<a id="source-${n}"></a>\n\n${n}. ${t}\n`);
 md=md.replace(/\[\^(\d+)\]/g,(_,n)=>`<sup><a href="#source-${n}">${n}</a></sup>`);
 md=md.replaceAll('(notes/effects.md)','(notes/effects.html)').replaceAll('(notes/story-arc.md)','(notes/story-arc.html)');
 const body=marked.parse(md),title=md.match(/^# (.+)/m)[1];
 const html=`<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>${title}</title><style>body{font:17px/1.65 system-ui,sans-serif;color:#222;background:#fafafa;margin:0}main{max-width:1040px;margin:auto;padding:32px 30px 70px}h1{font-size:36px;line-height:1.2;letter-spacing:-1px;margin-bottom:28px}h2{font-size:26px;margin:48px 0 14px;border-top:1px solid #bbb;padding-top:20px}h3{font-size:20px;margin:26px 0 10px}p{max-width:900px}a{color:#245267}table{border-collapse:collapse;font-size:14px;line-height:1.5;width:100%;display:block;overflow:auto}th,td{text-align:left;vertical-align:top;padding:12px;border-bottom:1px solid #ccc;min-width:110px}th{background:#e9edef}nav{display:flex;gap:22px;margin-bottom:28px;font-size:14px}code{font-size:.88em}sup{line-height:0}li{margin:7px 0}a:focus-visible{outline:3px solid #387da0}@media print{body{font-size:11pt;background:white}main{padding:0}nav{display:none}h2{break-after:avoid}table{display:table;font-size:9pt}tr{break-inside:avoid}}</style><main><nav><a href="${sub?'../':''}maps/atlas.html">Level atlas</a><a href="${sub?'../EXPLORATION-DESIGN.html':'notes/effects.html'}">${sub?'Design report':'Effects study'}</a><a href="${sub?'../':''}notes/story-arc.html">Story study</a><a href="${path.basename(relative)}">Markdown source</a></nav>${body}</main></html>`;
 fs.writeFileSync(src.replace(/\.md$/,'.html'),html);
 console.log('Rendered '+relative);
}

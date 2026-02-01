import express from "express";
const app = express();
const port = process.env.PORT ? Number(process.env.PORT) : 3000;
app.get("/healthz", (_req, res) => res.status(200).send("ok"));
app.get("/", (_req, res) => res.json({ service: "learning-api", status: "running" }));
app.listen(port, "0.0.0.0", () => {
    console.log(`Listening on :${port}`);
});
//# sourceMappingURL=index.js.map
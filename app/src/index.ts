import express from "express";

const app = express();

app.use((req, res, next) => {
  const start = Date.now();
  res.on("finish", () => {
    const ms = Date.now() - start;
    console.log(`${req.method} ${req.path} -> ${res.statusCode} (${ms}ms)`);
  });
  next();
});

const port = process.env.PORT ? Number(process.env.PORT) : 3000;

app.get("/healthz", (_req, res) => res.status(200).send("ok"));
app.get("/", (_req, res) => res.json({ service: "learning-api", status: "running" }));

app.listen(port, "0.0.0.0", () => {
  console.log(`Listening on :${port}`);
});

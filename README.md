<head>
  <title>stormy's Dots</title>
  <link href="https://fonts.googleapis.com/css2?family=Press+Start+2P&display=swap" rel="stylesheet">
  <style>
    body {
      display: flex;
      justify-content: center;
      align-items: center;
      /*height: 100vh;*/
	  margin: 0;
	  padding: 0;
    }

    h1 {
      font-family: 'Press Start 2P', monospace;
      font-size: 60px;
      text-transform: uppercase;
      background: linear-gradient(90deg, #ff914d, #ff4d78, #c54dff, #4da6ff, #00e6a8, #66cc66);
      -webkit-background-clip: text;
      color: transparent;
      position: relative;
    }

    h1::before {
      content: "STORMY'S DOTS";
      position: absolute;
      left: 6px;
      top: 6px;
      color: transparent;
      -webkit-text-stroke: 2px #333;
      z-index: -1;
	  white-space: nowrap;
	  width: max-content;
    }

  </style>
</head>
<body>
  <h1>STORMY'S DOTS</h1>
</body>

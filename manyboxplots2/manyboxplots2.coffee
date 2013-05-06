# manyboxplots2.coffee
#
# Top panel is like ~500 box plots:
#   lines are drawn at the 0.1 1, 10, 25, 50, 75, 90, 99, 99.9 percentiles
#   for each of ~500 distributions
# Hover over a column in the top panel and the corresponding distribution
#   is show below; click for it to persist; click again to make it go away.
#

# function that does all of the work
# load json file and call draw function
d3.json("data.json", (data) ->

  # dimensions of SVG
  w = 1000
  h = 450
  pad = {left:60, top:20, right:60, bottom: 40}

  # y-axis limits for top figure
  topylim = [data.quant[0][0], data.quant[0][1]]
  for i of data.quant
    for x in data.quant[i]
      topylim[0] = x if x < topylim[0]
      topylim[1] = x if x > topylim[1]
  topylim[0] = Math.floor(topylim[0])
  topylim[1] = Math.ceil(topylim[1])
  
  # y-axis limits for bottom figure
  botylim = [0, data.counts[0][1]]
  for i of data.counts
    for x in data.counts[i]
      botylim[1] = x if x > botylim[1]

  console.log("data.ind.length: #{data.ind.length}")
  console.log("data.breaks.length: #{data.breaks.length}")
  console.log("data.qu.length: #{data.qu.length}")
  console.log("data.quant.length: #{data.quant.length}")
  console.log("data.quant[0].length: #{data.quant[0].length}")
  console.log("data.counts.length: #{data.counts.length}")
  console.log("data.counts[0].length: #{data.counts[0].length}")

  indindex = d3.range(data.ind.length)

  # adjust counts object to make proper histogram
  br2 = []
  for i in data.breaks
    br2.push(i)
    br2.push(i)

  fix4hist = (d) ->
    x = [0]
    for i in d
       x.push(i)
       x.push(i)
    x.push(0)
    x

  for i of data.counts
    data.counts[i] = fix4hist(data.counts[i])

  # number of quantiles
  nQuant = data.quant.length
  midQuant = (nQuant+1)/2 - 1

  # x and y scales for top figure
  xScale = d3.scale.linear()
             .domain([0, data.ind.length+1])
             .range([pad.left, w-pad.right])

  yScale = d3.scale.linear()
             .domain(topylim)
             .range([h-pad.bottom, pad.top])

  # function to create quantile lines
  quline = (j) ->
    d3.svg.line()
        .x((d) -> xScale(d+1))
        .y((d) -> yScale(data.quant[j][d]))

  svg = d3.select("body").append("svg")
          .attr("width", w)
          .attr("height", h)

  # gray background
  svg.append("rect")
     .attr("x", pad.left)
     .attr("y", pad.top)
     .attr("height", h-pad.top-pad.bottom)
     .attr("width", w-pad.left-pad.right)
     .attr("stroke", "none")
     .attr("fill", d3.rgb(200, 200, 200))

  # axis on left
  LaxisData = yScale.ticks(6)
  Laxis = svg.append("g")

  # axis: white lines
  Laxis.append("g").selectAll("empty")
     .data(LaxisData)
     .enter()
     .append("line")
     .attr("class", "line")
     .attr("class", "axis")
     .attr("x1", pad.left)
     .attr("x2", w-pad.right)
     .attr("y1", (d) -> yScale(d))
     .attr("y2", (d) -> yScale(d))
     .attr("stroke", "white")

  # axis: labels
  Laxis.append("g").selectAll("empty")
     .data(LaxisData)
     .enter()
     .append("text")
     .attr("class", "axis")
     .text((d) -> d3.format(".0f")(d))
     .attr("x", pad.left*0.9)
     .attr("y", (d) -> yScale(d))
     .attr("dominant-baseline", "middle")
     .attr("text-anchor", "end")


  # axis on bottom
  BaxisData = xScale.ticks(10)
  Baxis = svg.append("g")

  # axis: white lines
  Baxis.append("g").selectAll("empty")
     .data(BaxisData)
     .enter()
     .append("line")
     .attr("class", "line")
     .attr("class", "axis")
     .attr("y1", pad.top)
     .attr("y2", h-pad.bottom)
     .attr("x1", (d) -> xScale(d))
     .attr("x2", (d) -> xScale(d))
     .attr("stroke", "white")

  # axis: labels
  Baxis.append("g").selectAll("empty")
     .data(BaxisData)
     .enter()
     .append("text")
     .attr("class", "axis")
     .text((d) -> d)
     .attr("y", h-pad.bottom*0.75)
     .attr("x", (d) -> xScale(d))
     .attr("dominant-baseline", "middle")
     .attr("text-anchor", "middle")


  # colors for quantile curves
  colindex = d3.range((nQuant-1)/2)
  tmp = d3.scale.category10().domain(colindex)
  qucolors = []
  for j in colindex
    qucolors.push(tmp(j))
  qucolors.push("black")
  for j in colindex.reverse()
    qucolors.push(tmp(j))

  # curves for quantiles
  curves = svg.append("g")

  for j in [0...nQuant]
    curves.append("path")
       .datum(indindex)
       .attr("d", quline(j))
       .attr("class", "line")
       .attr("stroke", qucolors[j])

  # special rectangles in the background
  clickStatus = {}
  index = {}
  specialrects = svg.append("g")
  for d in indindex
    clickStatus[d] = 0
    specialrects.append("rect")
       .attr("x", xScale(d+0.5))
       .attr("y", yScale(data.quant[nQuant-1][d]))
       .attr("width", 2)
       .attr("id", data.ind[d])
       .attr("height", yScale(data.quant[0][d]) - yScale(data.quant[nQuant-1][d]))
       .attr("opacity", 0)
       .attr("stroke", "none")

  # vertical rectangles representing each array
  indRectGrp = svg.append("g")

  indRect = indRectGrp.selectAll("empty")
                 .data(indindex)
                 .enter()
                 .append("rect")
                 .attr("x", (d) -> xScale(d+0.5))
                 .attr("y", (d) -> yScale(data.quant[nQuant-1][d]))
                 .attr("id", (d) -> data.ind[d])
                 .attr("width", 2)
                 .attr("height", (d) ->
                    yScale(data.quant[0][d]) - yScale(data.quant[nQuant-1][d]))
                 .attr("fill", "purple")
                 .attr("stroke", "none")
                 .attr("opacity", "0")

  # label quantiles on right
  rightAxis = svg.append("g")

  rightAxis.selectAll("empty")
       .data(data.qu)
       .enter()
       .append("text")
       .attr("class", "qu")
       .text( (d) -> "#{d*100}%")
       .attr("x", w)
       .attr("y", (d,i) -> yScale(((i+0.5)/nQuant/2 + 0.25) * (topylim[1] - topylim[0]) + topylim[0]))
       .attr("fill", (d,i) -> qucolors[i])
       .attr("text-anchor", "end")
       .attr("dominant-baseline", "middle")

  # white box above to smother overlap
  svg.append("rect")
     .attr("x", 0)
     .attr("y", 0)
     .attr("width", w)
     .attr("height", pad.top)
     .attr("stroke", "none")
     .attr("fill", "white")

  # box around the outside
  svg.append("rect")
     .attr("x", pad.left)
     .attr("y", pad.top)
     .attr("height", h-pad.top-pad.bottom)
     .attr("width", w-pad.left-pad.right)
     .attr("stroke", "black")
     .attr("stroke-width", 2)
     .attr("fill", "none")

  # lower svg
  lowsvg = d3.select("body").append("svg")
             .attr("height", h)
             .attr("width", w)

  lo = data.breaks[0] - (data.breaks[1] - data.breaks[0])
  hi = data.breaks[data.breaks.length-1] + (data.breaks[1] - data.breaks[0])

  lowxScale = d3.scale.linear()
             .domain([lo, hi])
             .range([pad.left, w-pad.right])

  lowyScale = d3.scale.linear()
             .domain([0, botylim[1]+1])
             .range([h-pad.bottom, pad.top])

  # gray background
  lowsvg.append("rect")
     .attr("x", pad.left)
     .attr("y", pad.top)
     .attr("height", h-pad.top-pad.bottom)
     .attr("width", w-pad.left-pad.right)
     .attr("stroke", "none")
     .attr("fill", d3.rgb(200, 200, 200))

  # axis on left
  lowBaxisData = lowxScale.ticks(8)
  lowBaxis = lowsvg.append("g")

  # axis: white lines
  lowBaxis.append("g").selectAll("empty")
     .data(lowBaxisData)
     .enter()
     .append("line")
     .attr("class", "line")
     .attr("class", "axis")
     .attr("y1", pad.top)
     .attr("y2", h-pad.bottom)
     .attr("x1", (d) -> lowxScale(d))
     .attr("x2", (d) -> lowxScale(d))
     .attr("stroke", "white")

  # axis: labels
  lowBaxis.append("g").selectAll("empty")
     .data(lowBaxisData)
     .enter()
     .append("text")
     .attr("class", "axis")
     .text((d) -> d3.format(".0f")(d))
     .attr("y", h-pad.bottom*0.75)
     .attr("x", (d) -> lowxScale(d))
     .attr("dominant-baseline", "middle")
     .attr("text-anchor", "middle")

  grp4BkgdHist = lowsvg.append("g")

  histline = d3.svg.line()
        .x((d,i) -> lowxScale(br2[i]))
        .y((d) -> lowyScale(d))

  randomInd = indindex[Math.floor(Math.random()*data.ind.length)]
  console.log("randomInd: #{randomInd}")

  hist = lowsvg.append("path")
    .datum(data.counts[randomInd])
       .attr("d", histline)
       .attr("id", "histline")
       .attr("fill", "none")
       .attr("stroke", "purple")
       .attr("stroke-width", "2")


  histColors = ["blue", "red", "green", "orange", "black"]

  lowsvg.append("text")
        .datum(randomInd)
        .attr("x", pad.left*1.1)
        .attr("y", pad.top*2)
        .text((d) -> data.ind[d])
        .attr("id", "histtitle")
        .attr("text-anchor", "start")
        .attr("dominant-baseline", "middle")
        .attr("fill", "blue")

  indRect
    .on "mouseover", (d) ->
              d3.select(this)
                 .attr("opacity", "1")
              d3.select("#histline")
                 .datum(data.counts[d])
                 .attr("d", histline)
              d3.select("#histtitle")
                 .datum(d)
                 .text((d) -> data.ind[d])

    .on "mouseout", (d) ->
              d3.select(this).attr("opacity", "0")

    .on "click", (d) ->
              console.log(d)
              console.log(data.ind[d])
              clickStatus[d] = 1 - clickStatus[d]
              svg.select("rect##{data.ind[d]}").attr("opacity", clickStatus[d])
              if clickStatus[d]
                curcolor = histColors.shift()
                histColors.push(curcolor)

                d3.select(this).attr("opacity", "0")
                svg.select("rect##{data.ind[d]}").attr("fill", curcolor)

                grp4BkgdHist.append("path")
                      .datum(data.counts[d])
                      .attr("d", histline)
                      .attr("id", data.ind[d])
                      .attr("fill", "none")
                      .attr("stroke", curcolor)
                      .attr("stroke-width", "2")
              else
                grp4BkgdHist.select("path##{data.ind[d]}").remove()

  # white box above to smother overlap
  lowsvg.append("rect")
     .attr("x", 0)
     .attr("y", 0)
     .attr("width", w)
     .attr("height", pad.top)
     .attr("stroke", "none")
     .attr("fill", "white")

  # white box to left smother overlap
  lowsvg.append("rect")
     .attr("x", 0)
     .attr("y", 0)
     .attr("width", pad.left)
     .attr("height", h)
     .attr("stroke", "none")
     .attr("fill", "white")

  # box around the outside
  lowsvg.append("rect")
     .attr("x", pad.left)
     .attr("y", pad.top)
     .attr("height", h-pad.bottom-pad.top)
     .attr("width", w-pad.left-pad.right)
     .attr("stroke", "black")
     .attr("stroke-width", 2)
     .attr("fill", "none")


  svg.append("text")
     .text("Outcome")
     .attr("x", pad.left*0.2)
     .attr("y", h/2)
     .attr("fill", "blue")
     .attr("transform", "rotate(270 #{pad.left*0.2} #{h/2})")
     .attr("dominant-baseline", "middle")
     .attr("text-anchor", "middle")

  lowsvg.append("text")
     .text("Outcome")
     .attr("x", (w-pad.left-pad.bottom)/2+pad.left)
     .attr("y", h-pad.bottom*0.2)
     .attr("fill", "blue")
     .attr("dominant-baseline", "middle")
     .attr("text-anchor", "middle")

  svg.append("text")
     .text("Individuals, sorted by median")
     .attr("x", (w-pad.left-pad.bottom)/2+pad.left)
     .attr("y", h-pad.bottom*0.2)
     .attr("fill", "blue")
     .attr("dominant-baseline", "middle")
     .attr("text-anchor", "middle")
)
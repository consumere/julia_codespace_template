using Dash
using CSV
using DataFrames
using PlotlyJS
using Base64
using Dates

# app = Dash.dash(;
# external_scripts=["https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.5/MathJax.js?config=TeX-MML-AM_CHTML"],
# update_title="Loading...")

#app = Dash.dash(;update_title="Loading...")
app = Dash.dash(
    external_stylesheets=[
        "https://stackpath.bootstrapcdn.com/bootstrap/4.4.1/css/bootstrap.min.css",
        "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/4.7.0/css/font-awesome.min.css"
    ],
    update_title="Loading..."
)
#methods(dash)
#methods(html_div)

app.layout = html_div() do
    [
    html_h2("WaSiM Timeseries Data"),    
    dcc_upload(
            id = "upload-data",
            children = [
                html_div("Drag and Drop or "),
                html_a("Select Files")
            ],
            style = Dict(
                "width" => "99%",
                "height" => "60px",
                "lineHeight" => "60px",
                "borderWidth" => "1.5px",
                "borderStyle" => "dashed",
                "borderRadius" => "5px",
                "textAlign" => "center",
                "margin" => "10px"
            ),
            multiple = true
        ),
        html_div(id = "output-graph")
    ]
end

function parse_contents(contents, filename)
    # Read the contents of the uploaded file
    content_type, content_string = split(contents, ',')

    # Decode the file content
    decoded = base64decode(content_string)

    ms = ["-9999.0", "-9999", "lin", "log", "--"]

    df = CSV.File(IOBuffer(decoded); delim="\t", header=1, normalizenames=true,
        missingstring=ms, types=Float64) |> DataFrame

    # df = CSV.read(IOBuffer(decoded), DataFrame;
    #     delim="\t",header=1,
    #     silencewarnings=true,
    #     missingstring=ms,
    #     types=Float64)
    
    
    dropmissing!(df, 1)

    for i in 1:3
        df[!, i] = map(x -> Int(x), df[!, i])
    end

    df.date = Date.(string.(df[!, 1], "-", df[!, 2], "-", df[!, 3]), "yyyy-mm-dd")
    #df.date = Date.(string.(df[!, 1], "\t", df[!, 2], "\t", df[!, 3]), "yyyy\tMM\tDD")

    df = df[:, Not(1:4)]
    #dropmissing!(df)

    fig = PlotlyJS.make_subplots(shared_xaxes=true, shared_yaxes=true)
    #fig = PlotlyJS.make_subplots(shared_xaxes=true)
    #fig = PlotlyJS.make_subplots()

    function yrsum(x::DataFrame)
        df = copy(x)
        y = filter(x->!occursin("date",x),names(df))
        s = map(y -> Symbol(y),y)
        df[!, :year] = year.(df[!,:date]);
        df_yearsum = DataFrames.combine(groupby(df, :year), y .=> sum .=> y);
        return(df_yearsum)
    end

    tcols = size(df)[2] - 1

    for i in 1:tcols
        PlotlyJS.add_trace!(fig, 
        PlotlyJS.scatter(x=df.date, y=df[:, i], name=names(df)[i])
        )
    end



    ti = filename
    fact = 1.1
    #fact = .8

#    Add dropdown
    PlotlyJS.relayout!(fig,
    template="seaborn",
    #template="simple_white",
    #template="plotly_dark",
    height=650*fact,
    width=1200*fact,
    title_text=filename,
    #xperiod = first(df.date),
    #xperiodalignment = "start",
    updatemenus=[
        Dict(
            "type" => "buttons",
            "direction" => "left",
            "buttons" => [
                Dict(
                    "args" => [Dict("yaxis.type" => "linear")],
                    "label" => "Linear Scale",
                    "method" => "relayout"
                ),
                Dict(
                    "args" => [Dict("yaxis.type" => "log")],
                    "label" => "Log Scale",
                    "method" => "relayout"
                )
            ],
            "pad" => Dict("r" => 1, "t" => 10),
            "showactive" => true,
            "x" => 0.11,
            #"x" => 5.11,
            "xanchor" => "left",
            #"xanchor" => "auto",
            "y" => 1.1,
            #"yanchor" => "top"
            "yanchor" => "auto"
        ),
    ]
    )

    # Add annotations --> this changes pos. of y-axis.. bad.. (

    # PlotlyJS.relayout!(fig,
    #     annotations=[
    #         Dict("text" => "Y-Axis:", "showarrow" => false,
    #             "x" => 0, "y" => 1.08, 
    #             "yref" => "paper", 
    #             #"yref" => "container", 
    #             #"align" => "left")
    #             #"align" => "right")
    #             "align" => "auto")
    #     ]
    # )

    return fig
end


callback!(
    app,
    Output("output-graph", "children"),
    [Input("upload-data", "contents")],
    [State("upload-data", "filename")]
) do contents, filenames
    if contents !== nothing
        graphs = []
        for (content, filename) in zip(contents, filenames)
            graph = html_div([
                #html_h4(filename),
                dcc_graph(
                    id = filename,
                    figure = parse_contents(content, filename) #, filename
                )
            ])
            push!(graphs, graph)
        end
        return graphs
    end
end

run_server(app, debug=true)


#run_server(app, "127.0.0.1", 8050)






















# function parse_contents(contents, filename)
#     # Read the contents of the uploaded file
#     content_type, content_string = split(contents, ',')
#     # Decode the file content
#     decoded = base64decode(content_string)
    
    
#     ms = ["-9999.0", "-9999", "lin", "log", "--"]
#     #x=raw"D:\Wasim\Tanalys\DEM\Input_V2\meteo\rad.2021"
    
#     # df = CSV.read(IOBuffer(decoded), DataFrame;
#     #     delim="\t",header=1,
#     #     silencewarnings=true,
#     #     missingstring=ms,
#     #     types=Float64)
#     df = CSV.File(IOBuffer(decoded); delim="\t", header=1, normalizenames=true, 
#         missingstring=ms, types=Float64) |> DataFrame
    
#     # df = CSV.File(x; delim="\t", header=1, normalizenames=true, 
#     #     missingstring=ms, types=Float64) |> DataFrame

#     dropmissing!(df,1)
    
#     for i in 1:3
#         df[!,i]=map(x ->Int(x),df[!,i])
#     end
#     #and parse dates...
#     df.date = Date.(string.(df[!,1],"-",df[!,2],"-",df[!,3]),"yyyy-mm-dd");
#     df=df[:,Not(1:4)]
    
#     fig = PlotlyJS.make_subplots(
#         shared_xaxes=true, 
#         shared_yaxes=true    
#         );
#     #ti = " " #placeholder
#     ti = filename
    
#     tcols=size(df)[2]-1
    
#     for i in 1:tcols;
#         PlotlyJS.add_trace!(fig, 
#         #PlotlyJS.bar(
#         PlotlyJS.scatter(   
#             x=df.date, y=df[:,i],
#             name=names(df)[i]));
#     end
#     # Add dropdown
#     PlotlyJS.relayout!(fig,
#     updatemenus=[
#         attr(
#             type = "buttons",
#             direction = "left",
#             buttons=[
#                 attr(
#                     args=["yaxis.type", "linear"],
#                     label="Linear Scale",
#                     method="restyle"
#                 ),
#                 attr(
#                     args=["yaxis.type", "log"],
#                     label="Log Scale",
#                     method="restyle"
#                 )
#             ],
#             pad=attr(r= 10, t=10),
#             showactive=true,
#             x=0.11,
#             xanchor="left",
#             y=1.1,
#             yanchor="top"
#         ),
#     ]
#     )

#     # Add annotation
#     # set other layout options
#     fact = 1.1
#     PlotlyJS.relayout!(fig,
#     template="seaborn",
#     height=600*fact,width=900*fact,
#     title_text=filename,
#     annotations=[
#         attr(text="Trace type:", showarrow=false,
#                             x=0, y=1.08, yref="paper", align="left")
#     ]
#     )

  
#     return fig
# end



# # Add dropdown
# relayout!(p,
#     updatemenus=[
#         attr(
#             type = "buttons",
#             direction = "left",
#             buttons=[
#                 attr(
#                     args=["type", "surface"],
#                     label="3D Surface",
#                     method="restyle"
#                 ),
#                 attr(
#                     args=["type", "heatmap"],
#                     label="Heatmap",
#                     method="restyle"
#                 )
#             ],
#             pad=attr(r= 10, t=10),
#             showactive=true,
#             x=0.11,
#             xanchor="left",
#             y=1.1,
#             yanchor="top"
#         ),
#     ]
# )

# # Add annotation
# relayout!(p,
#     annotations=[
#         attr(text="Trace type:", showarrow=false,
#                              x=0, y=1.08, yref="paper", align="left")
#     ]
# )
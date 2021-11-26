

# Create a table of all markets and their prize development
# fields: MARKET, COURSE, REF_COURSE, REF_TIME, REL_PRIZE
# ref_market should be passed only when buying a coin
function rel_price_table(df, ref_time, rel_price_table = nothing; ref_market=nothing)
    markets = names(df)[2:end]
    if isnothing(rel_price_table)
        init = true
    else
        init = false
    end
    if init
        for market in markets
            ref_course = first(df[!, market])
            if isnothing(rel_price_table)
                rel_price_table = DataFrame(MARKET = market, REF_COURSE=ref_course, REF_TIME=ref_time, REL_PRIZE=1.0)
            else
                rel_prize = 1.0
                v = [market, ref_course, ref_time, rel_prize]
                push!(rel_price_table, v)
            end
        end
    else
        if ! isnothing(ref_market)
            for row in eachrow(rel_price_table)
                market=row.MARKET
                if market==ref_market
                    course = last(df[!, market])
                    row.REF_COURSE = course
                    println("old REL_PRIZE: ", row.REL_PRIZE, ", new REL_PRIZE: ", course/row.REF_COURSE)
                    row.REL_PRIZE = course/row.REF_COURSE
                end
            end
        else
            for row in eachrow(rel_price_table)
                market=row.MARKET
                course = last(df[!, market])
                row.REL_PRIZE = course/row.REF_COURSE
            end
        end
    end
    rel_price_table
end

function rel_price(rel_price_table, market)
    rel_price_table[(rel_price_table.MARKET .== market), :REL_PRIZE][1]
end
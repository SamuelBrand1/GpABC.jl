using KernelDensity
using PyPlot

# This script relies on data (emu_out, sim_out) that is generated by running smc-abc-script.jl
function plot_emulation_vs_simulation(emu_out, sim_out, plot_emu_iterations)
            grid_size = emu_out.n_params
            emu_handle = nothing
            sim_handle = nothing
            kernel_bandwidth_scale = 0.09
            bounds_scale = 1.2
            population_colors = ["#DDF4F7", "#B1E9DE", "#63D3BB", "#00BD8B", "#007731"]

            contour_colors = ["white", "#FFE9EC", "#FFBBC5", "#FF8B9C", "#FF5D75", "#FF2F4E", "#D0001F", "#A20018", "#990017", "#800013"]
            simulation_color = "#08519c"
            emulation_color = "#ff6600"
            for i in 1:grid_size
                for j in 1:grid_size
                    if j < i
                        subplot2grid((grid_size, grid_size), (i - 1, j - 1))
                        x_data_emu = emu_out.population[end][:,j]
                        y_data_emu = emu_out.population[end][:,i]
                        x_data_sim = sim_out.population[end][:,j]
                        y_data_sim = sim_out.population[end][:,i]
                        sim_size = size(sim_out.population[end], 1)
                        if sim_size > 20
                            # idx = sample(range(1,sim_size))
                            x_data_sim = x_data_sim[1:20]
                            y_data_sim = y_data_sim[1:20]
                        end
                        x_extr_emu = extrema(x_data_emu)
                        y_extr_emu = extrema(y_data_emu)
                        x_extr_sim = extrema(x_data_sim)
                        y_extr_sim = extrema(y_data_sim)

                        x_min = min(x_extr_emu[1], x_extr_sim[1])
                        x_max = max(x_extr_emu[2], x_extr_sim[2])
                        x_mid = (x_min + x_max) / 2
                        x_diff = (x_max - x_min) / 2
                        x_bounds =  (-x_diff, x_diff) .* bounds_scale .+ x_mid
                        y_min = min(y_extr_emu[1], y_extr_sim[1]) * 0.9
                        y_max = max(y_extr_emu[2], y_extr_sim[2]) * 1.1
                        y_mid = (y_min + y_max) / 2
                        y_diff = (y_max - y_min) / 2
                        y_bounds =  (-y_diff, y_diff) .* bounds_scale .+ y_mid
                        xlim(x_bounds)
                        ylim(y_bounds)

                        bandwidth = (-kernel_bandwidth_scale * -(x_extr_emu...), -kernel_bandwidth_scale * -(y_extr_emu...))
                        kde_joint = kde((x_data_emu, y_data_emu), bandwidth=bandwidth)
                        contour_x = linspace(x_bounds..., 100)
                        contour_y = linspace(y_bounds..., 100)
                        contour_z = pdf(kde_joint, contour_x, contour_y)
                        # contourf(contour_x, contour_y, contour_z, 8, colors=contour_colors, zorder=1)
                        contourf(contour_x, contour_y, contour_z, 8, colors=contour_colors, zorder=1)

                        scatter(x_data_sim, y_data_sim, marker="x", color=simulation_color, zorder=2, alpha=0.9)
                        # xlabel("Parameter $i")
                        # ylabel("Parameter $j")
                    elseif (j > i) && plot_emu_iterations
                        subplot2grid((grid_size, grid_size), (i - 1, j - 1))
                        for iter_idx in 1:length(emu_out.population)
                            scatter(emu_out.population[iter_idx][:,j], emu_out.population[iter_idx][:,i],
                                color=population_colors[iter_idx], zorder=iter_idx)
                        end
                    elseif i == j
                        subplot2grid((grid_size, grid_size), (i - 1, j - 1))
                        emu_data = emu_out.population[end][:,i]
                        sim_data = sim_out.population[end][:,i]
                        extr_emu = extrema(emu_data)
                        extr_sim = extrema(sim_data)
                        kde_emu = kde(emu_data, bandwidth=-kernel_bandwidth_scale * -(extr_emu...))
                        kde_sim = kde(sim_data, bandwidth=-kernel_bandwidth_scale * -(extr_sim...))
                        x_min = min(extr_emu[1], extr_sim[1])
                        x_max = max(extr_emu[2], extr_sim[2])
                        x_mid = (x_min + x_max) / 2
                        x_diff = (x_max - x_min) / 2
                        x_bounds = (-x_diff, x_diff) .* bounds_scale .+ x_mid
                        xlim(x_bounds)
                        x_plot = linspace(x_bounds..., 100)
                        y_emu_plot = pdf(kde_emu,x_plot)
                        y_sim_plot = pdf(kde_sim,x_plot)
                        emu_handle = plot(x_plot, y_emu_plot, color=emulation_color)
                        sim_handle = plot(x_plot, y_sim_plot, color=simulation_color)
                        # xlabel("Parameter $i")
                        yticks([])
                    end
                end
            end
            # if grid_size > 1
            #     subplot2grid((grid_size, grid_size), (0, 1))
            #     legend([emu_handle; sim_handle], ["Emulation", "Simulation"], loc="upper left")
            #     axis("off")
            # else
            # figlegend([emu_handle; sim_handle], ["Emulation", "Simulation"], loc="upper right")
            # end
end

sim_out1 = GpABC.SimulatedABCSMCOutput(sim_out.n_params, sim_out.n_accepted[1:end-1],
                        sim_out.n_tries[1:end-1], sim_out.threshold_schedule[1:end-1],
                        sim_out.population[1:end-1], sim_out.distances[1:end-1],
                        sim_out.weights[1:end-1])

emu_out1 = GpABC.EmulatedABCSMCOutput(emu_out.n_params, emu_out.n_accepted[1:end-1],
                        emu_out.n_tries[1:end-1], emu_out.threshold_schedule[1:end-1],
                        emu_out.population[1:end-1], emu_out.distances[1:end-1],
                        emu_out.weights[1:end-1], emu_out.emulators[1:end-1])
ion()
fig = figure()
ioff()
plot_emulation_vs_simulation(emu_out, sim_out, true)
subplots_adjust(
left    =  0.08,
bottom  =  0.06,
right   =  0.96,
top     =  0.97,
wspace  =  0.26,
hspace  =  0.26)
show(fig)

# savefig("/Users/tanhevg/Desktop/projects/gaussian_processes/Bioinformatics paper/fig-1b-res-3-gene-no-pop.eps")

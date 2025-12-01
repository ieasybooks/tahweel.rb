# frozen_string_literal: true

require "io/console"

module Tahweel
  module CLI
    # Handles thread-safe rendering of the progress dashboard for the CLI.
    #
    # This class manages ANSI escape codes to create a dynamic, multi-line progress display
    # showing global status and individual worker threads.
    class ProgressRenderer
      # ANSI Color Codes
      RESET = "\e[0m"
      BOLD = "\e[1m"
      RED = "\e[31m"
      GREEN = "\e[32m"
      YELLOW = "\e[33m"
      BLUE = "\e[34m"
      CYAN = "\e[36m"
      DIM = "\e[2m"

      # Initializes the renderer and prepares the terminal.
      #
      # @param total_files [Integer] Total number of files to process.
      # @param concurrency [Integer] Number of concurrent worker threads.
      def initialize(total_files, concurrency) # rubocop:disable Metrics/MethodLength
        @total_files = total_files
        @concurrency = concurrency
        @processed_files = 0
        @worker_states = Array.new(concurrency)
        @mutex = Mutex.new
        @start_time = Time.now
        @running = true

        # Hide cursor
        $stdout.print "\e[?25l"

        # Reserve space for global status + 1 line per worker
        $stdout.print "\n" * (@concurrency + 1)

        # Trap Interrupt to restore cursor
        trap("INT") do
          @running = false
          $stdout.print "\e[?25h"
          exit
        end

        start_ticker
      end

      # Updates the state for a worker starting a new file.
      #
      # @param worker_index [Integer] The index of the worker thread (0-based).
      # @param file [String] The path of the file being started.
      def start_file(worker_index, file)
        @mutex.synchronize do
          @worker_states[worker_index] = {
            file:,
            stage: "Starting...",
            percentage: 0,
            details: ""
          }
        end
      end

      # Updates the progress for a specific worker.
      #
      # @param worker_index [Integer] The index of the worker thread.
      # @param progress [Hash] The progress hash containing stage, percentage, etc.
      def update(worker_index, progress)
        @mutex.synchronize do
          return unless @worker_states[worker_index]

          stage = progress[:stage].to_s.capitalize
          percentage = progress[:percentage]
          current_page = progress[:current_page]
          total_pages = current_page + progress[:remaining_pages]

          @worker_states[worker_index][:stage] = stage
          @worker_states[worker_index][:percentage] = percentage
          @worker_states[worker_index][:details] = "(#{current_page}/#{total_pages})"
        end
      end

      # Marks a worker as finished with its current file.
      #
      # @param worker_index [Integer] The index of the worker thread.
      def finish_file(worker_index)
        @mutex.synchronize do
          @processed_files += 1
          @worker_states[worker_index] = nil # Idle
        end
      end

      # Restores the cursor and finalizes the display.
      def finish_all
        @running = false
        @ticker_thread&.join
        render # Ensure final state is drawn
        $stdout.print "\e[?25h"
      end

      private

      def start_ticker
        @ticker_thread = Thread.new do
          while @running
            sleep 0.5
            @mutex.synchronize { render } if @running
          end
        end
      end

      def render # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
        # Move cursor up to the start of our block
        $stdout.print "\e[#{@concurrency + 1}A"

        # 1. Global Progress
        percent = @total_files.positive? ? ((@processed_files.to_f / @total_files) * 100).round(1) : 0
        elapsed = (Time.now - @start_time).round
        $stdout.print "\r\e[K" # Clear line
        puts "#{BOLD}Total Progress:#{RESET} [#{GREEN}#{@processed_files}#{RESET}/#{@total_files}] #{CYAN}#{percent}%#{RESET} | Time: #{YELLOW}#{elapsed}s#{RESET}" # rubocop:disable Layout/LineLength

        # 2. Worker Statuses
        @concurrency.times do |i|
          $stdout.print "\r\e[K" # Clear line
          state = @worker_states[i]
          if state
            # Limit filename length to avoid wrapping issues, truncate from beginning
            fname = truncate_path(state[:file], 40)
            stage_color = state[:stage] == "Splitting" ? BLUE : YELLOW
            puts " [Worker #{i + 1}] #{CYAN}#{fname}#{RESET} | #{stage_color}#{state[:stage].ljust(10)}#{RESET} | #{GREEN}#{state[:percentage].to_s.rjust(5)}%#{RESET} #{DIM}#{state[:details]}#{RESET}" # rubocop:disable Layout/LineLength
          else
            puts " [Worker #{i + 1}] #{DIM}Idle#{RESET}"
          end
        end

        $stdout.flush
      end

      def truncate_path(path, max_length)
        return path.ljust(max_length) if path.length <= max_length

        "...#{path[-(max_length - 3)..]}"
      end
    end
  end
end

import chess
import chess.engine
import asyncio

engine_path = "C:/Program Files/ChessEngines/stockfish_16/stockfish-windows-x86-64-avx2.exe"

if __name__ == "__main__" and hasattr(asyncio, 'WindowsProactorEventLoopPolicy'):
    asyncio.set_event_loop_policy(asyncio.WindowsProactorEventLoopPolicy())

with chess.engine.SimpleEngine.popen_uci(engine_path) as engine:
    board = chess.Board()  # Start with the initial position
    result = engine.analyse(board, chess.engine.Limit(time=0.1))  # Analyze the position

    print("Stockfish evaluation:", result["score"])
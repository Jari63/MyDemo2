using mydemo2.Application.TodoItems.Commands.CreateTodoItem;
using mydemo2.Application.TodoItems.Commands.UpdateTodoItem;
using mydemo2.Application.TodoItems.Commands.UpdateTodoItemDetail;
using mydemo2.Application.TodoLists.Commands.CreateTodoList;
using mydemo2.Domain.Entities;
using mydemo2.Domain.Enums;

namespace mydemo2.Application.FunctionalTests.TodoItems.Commands;

public class UpdateTodoItemDetailTests : TestBase
{
    [Test]
    public async Task ShouldRequireValidTodoItemId()
    {
        var command = new UpdateTodoItemCommand { Id = 99, Title = "New Title" };

        await Should.ThrowAsync<NotFoundException>(() => TestApp.SendAsync(command));
    }

    [Test]
    public async Task ShouldUpdateTodoItem()
    {
        var userId = await TestApp.RunAsDefaultUserAsync();

        var listId = await TestApp.SendAsync(new CreateTodoListCommand
        {
            Title = "New List"
        });

        var itemId = await TestApp.SendAsync(new CreateTodoItemCommand
        {
            ListId = listId,
            Title = "New Item"
        });

        var command = new UpdateTodoItemDetailCommand
        {
            Id = itemId,
            ListId = listId,
            Note = "This is the note.",
            Priority = PriorityLevel.High
        };

        await TestApp.SendAsync(command);

        var item = await TestApp.FindAsync<TodoItem>(itemId);

        item.ShouldNotBeNull();
        item!.ListId.ShouldBe(command.ListId);
        item.Note.ShouldBe(command.Note);
        item.Priority.ShouldBe(command.Priority);
        item.LastModifiedBy.ShouldNotBeNull();
        item.LastModifiedBy.ShouldBe(userId);
        item.LastModified.ShouldBe(DateTime.Now, TimeSpan.FromMilliseconds(10000));
    }
}
